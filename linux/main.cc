#include <fstream>
#include <nlohmann/json.hpp> // Include a JSON library

std::string GetLocalizedAppName() {
    std::string lang = getenv("LANG") ? getenv("LANG") : "en";
    std::string localeFile = "locale/en.json"; // Default to English

    if (lang.find("zh") != std::string::npos) {
        localeFile = "locale/zh.json";
    }

    std::ifstream file(localeFile);
    nlohmann::json locale;
    file >> locale;

    return locale["app_name"];
}

int main() {
    std::string appName = GetLocalizedAppName();
    std::cout << "App Name: " << appName << std::endl;
    return 0;
}