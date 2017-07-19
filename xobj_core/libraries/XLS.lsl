/*
	
	XOBJ Language Strings
	A simple translation manager for XOBJ, utilizing llGetAgentLanguage
	This is not included by default, but can be used in your project

	For macros in scripts that send readable texts, you can do something like:
	runMethod(targ, "got Language", LanguageMethod$text, [LANGUAGE_COMMON, xparse(targ, text), "", sound, vol], TNN)
	
*/

// Language constants
#define XLS_EN "en"     // English
#define XLS_DA "da"     // Dansk (Danish)
#define XLS_DE "de"     // Deutsch (German)
#define XLS_ES "es"     // Español (Spanish)
#define XLS_FR "fr"     // Français (French)
#define XLS_IT "it"     // Italiano (Italian)
#define XLS_HU "hu"     // Magyar (Hungarian)
#define XLS_NL "nl"     // Nederlands (Dutch)
#define XLS_PL "pl"     // Polski (Polish)
#define XLS_PT "pt"     // Portugués (Portuguese)
#define XLS_RU "ru"     // Русский (Russian)
#define XLS_TR "tr"     // Türkçe (Turkish)
#define XLS_UK "uk"     // Українська (Ukrainian)
#define XLS_ZH "zh"     // 中文 (简体) (Chinese)
#define XLS_JA "ja"     // 日本語 (Japanese)
#define XLS_KO "ko"     // 한국어 (Korean)

// Builds an xls object with multiple texts. Data is 2-strided list [(str)lang, (str)text]
#define XLS(data) "$XL$"+llList2Json(JSON_OBJECT, data)

// Default language to scan for if your viewer language is not supported
#ifndef XLS_LANG_DEFAULT
	#define XLS_LANG_DEFAULT XLS_EN
#endif

// Parse xls. Returns an empty string if language is not in the string.
string xparse(key user, string text){
    if(llGetSubString(text, 0, 3) != "$XL$")
        return text;
	if(user == NULL_KEY || user == "")
		user = llGetOwner();
    text = llGetSubString(text, 4, -1);    
    string lang = llToLower(llGetAgentLanguage(user));
    if(llJsonValueType(text, [lang]) != JSON_INVALID)
        return llJsonGetValue(text, [lang]);
    if(llJsonValueType(text, [XLS_LANG_DEFAULT]) != JSON_INVALID)
        return llJsonGetValue(text, [XLS_LANG_DEFAULT]);
    return "";
}

// X-parse with llGetOwner()
#define xme(text) xparse(llGetOwner(), text)


