import argparse
import json
import urllib.parse
from functools import wraps
from hashlib import md5
from random import randrange

import aiohttp
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import RedirectResponse

AES_KEY = b"e82ckenh8dichen8"
EAPI_URL = "https://interface3.music.163.com/eapi/song/enhance/player/url/v1"
PREFERRED_LEVELS = ("lossless", "exhigh", "standard")

app = FastAPI()


def HexDigest(data):
    return "".join(hex(b)[2:].zfill(2) for b in data)


def HashDigest(text):
    return md5(text.encode("utf-8")).digest()


def HashHexDigest(text):
    return HexDigest(HashDigest(text))


def parse_cookie(text):
    cookies = [item.strip().split("=", 1) for item in text.strip().split(";") if item]
    return {k.strip(): v.strip() for k, v in cookies}


def read_cookie():
    return "MUSIC_U=;os=pc;appver=8.9.75;"


async def post(url, params, cookie):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Safari/537.36 Chrome/91.0.4472.164 "
        "NeteaseMusicDesktop/2.10.2.200154",
        "Referer": "",
    }
    cookies = {
        "os": "pc",
        "appver": "",
        "osver": "",
        "deviceId": "pyncm!",
    }
    cookies.update(cookie)
    async with aiohttp.ClientSession(cookies=cookies, headers=headers) as session:
        async with session.post(url, data={"params": params}) as response:
            response.raise_for_status()
            return await response.text()


async def url_v1(song_id, level, cookies):
    config = {
        "os": "pc",
        "appver": "",
        "osver": "",
        "deviceId": "pyncm!",
        "requestId": str(randrange(20_000_000, 30_000_000)),
    }
    payload = {
        "ids": [song_id],
        "level": level,
        "encodeType": "flac",
        "header": json.dumps(config),
    }
    if level == "sky":
        payload["immerseType"] = "c51"

    path = urllib.parse.urlparse(EAPI_URL).path.replace("/eapi/", "/api/")
    payload_json = json.dumps(payload)
    digest = HashHexDigest(f"nobody{path}use{payload_json}md5forencrypt")
    params_raw = f"{path}-36cd479b6b5-{payload_json}-36cd479b6b5-{digest}"
    padder = padding.PKCS7(algorithms.AES(AES_KEY).block_size).padder()
    padded = padder.update(params_raw.encode()) + padder.finalize()
    cipher = Cipher(algorithms.AES(AES_KEY), modes.ECB())
    encryptor = cipher.encryptor()
    encrypted = encryptor.update(padded) + encryptor.finalize()
    params = HexDigest(encrypted)
    response_text = await post(EAPI_URL, params, cookies)
    return json.loads(response_text)


async def fetch_download_info(song_id, cookies):
    # Try preferred tiers from highest quality down until a playable URL appears.
    for level in PREFERRED_LEVELS:
        payload = await url_v1(song_id, level, cookies)
        data = payload.get("data") or []
        if not data:
            continue
        song = data[0]
        if song.get("url"):
            song["level"] = song.get("level") or level
            return song
    return None

@app.get("/download")
async def download_song(request: Request, song_id: str = Query(..., alias="id")):
    cookies = parse_cookie(read_cookie())
    song_info = await fetch_download_info(song_id, cookies)
    if not song_info:
        raise HTTPException(status_code=404, detail="未找到可用的下载链接")
    download_url = song_info.get("url")
    if not download_url:
        raise HTTPException(status_code=404, detail="未找到可用的下载链接")
    secure_url = download_url.replace("http://", "https://", 1)
    print(f"Redirecting to: {secure_url}")
    return RedirectResponse(secure_url)


def start_api():
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=5000)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="启动 API")
    parser.add_argument(
        "--mode", choices=["api"], default="api", help="选择启动模式：api"
    )
    args = parser.parse_args()
    if args.mode == "api":
        start_api()
