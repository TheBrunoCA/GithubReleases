/*
Author: TheBrunoCA
Github: https://github.com/TheBrunoCA
Original repository: https://github.com/TheBrunoCA/GithubReleases
*/

/*
Useful AHK v2 script for getting releases info.
*/

;---------Examples-----------

/*
    Creating the class object

username := "TheBrunoCA"
repository := "BuscaPMC"
git := GithubReleases(username, repository)

git.GetInfo()

json_map := git.GetJsonMap()

releases_array := git.GetListOfReleases(pre_release := false, online_only := false)

release := git.GetLatestRelease(pre_release := false, online_only := false)

release := git.GetLatestReleaseDownloadUrl(pre_release := false, online_only := false)

release := git.GetLatestReleaseVersion(pre_release := false, online_only := false)

release := git.IsUpToDate(current_version, pre_release := false, online_only := false)
*/

;---------End of Examples-----------

#Warn All, StdOut

Class GithubReleases{
    __New(user, repo) {
        this.user       := user
        this.repo       := repo
        this.url        := "https://api.github.com/repos/" this.user "/" this.repo "/releases"
        this.jsonPath   := A_Temp "\" this.user "-" this.repo ".json"
        this.is_online  := false
    }

    /*
    Get the releases info from "https://api.github.com/repos/username/repository/releases"
    and saves it into a Json on the A_Temp folder*/
    GetInfo(){
        response := _GetPageContent(this.url)
        if response == "" or (not InStr(response, this.user) and not InStr(response, this.repo))
            throw Error("GetInfo failed to get information from the repository")

        _FileOverwrite(response, this.jsonPath)
        this.is_online := true
    }

/*
    Returns a list of releases from the saved json.
    set "pre_release" to false to not get releases tagged as "prerelease".

    if "online_only" is set to true, GetInfo() must have been called at least once before it, else
    the json file will be used even if it is from another session as long as it exists.
*/
    GetListOfReleases(pre_release := false, online_only := false){
        if (online_only and this.is_online == false) or not FileExist(this.jsonPath)
            throw Error("The json is not updated or do not exist. Turn online_only to false or use GetInfo() first.")

        releases    := Array()
        json := this.GetJsonMap()

        loop json.Length{
            if json[A_Index]["prerelease"] and not pre_release
                continue

            releases.Push(this._GetReleaseMap(json[A_Index]))
        }
        if releases.Has(1)
            return releases

        throw Error("No release found.")
    }

/*
    Returns the latest release from the json file.
    set "pre_release" to false to not get a release tagged as "prerelease".

    if "online_only" is set to true, GetInfo() must have been called at least once before it, else
    the json file will be used even if it is from another session as long as it exists.

    This is just a Qol method, the same could be achieved with "GetListOfReleases()[1]"
    but optimized so as to not get every release before returning.
*/
    GetLatestRelease(pre_release := false, online_only := false){
        if (online_only and this.is_online == false) or not FileExist(this.jsonPath)
            throw Error("The json is not updated or do not exist. Turn online_only to false or use GetInfo() first.")

        json := this.GetJsonMap()

        loop json.Length{
            if json[A_Index]["prerelease"]
                continue
            return this._GetReleaseMap(json[A_Index])
        }
    }

/*
    Returns the latest release download url from the json file.
    set "pre_release" to false to not get a release tagged as "prerelease".

    if "online_only" is set to true, GetInfo() must have been called at least once before it, else
    the json file will be used even if it is from another session as long as it exists.

    This is just a Qol method, the same could be achieved with "GetLatestRelease()["download_url"]"
    but optimized so as to not get every release's info before returning.
*/
    GetLatestReleaseDownloadUrl(pre_release := false, online_only := false){
        if (online_only and this.is_online == false) or not FileExist(this.jsonPath)
            throw Error("The json is not updated or do not exist. Turn online_only to false or use GetInfo() first.")

        json := this.GetJsonMap()

        loop json.Length{
            if json[A_Index]["prerelease"]
                continue
            return json[A_Index]["assets"][1]["browser_download_url"]
        }
    }

/*
    Returns the latest release version from the json file.
    set "pre_release" to false to not get a release tagged as "prerelease".

    if "online_only" is set to true, GetInfo() must have been called at least once before it, else
    the json file will be used even if it is from another session as long as it exists.

    This is just a Qol method, the same could be achieved with "GetLatestRelease()["tag_name"]"
    but optimized so as to not get every release's info before returning.
*/
    GetLatestReleaseVersion(pre_release := false, online_only := false){
        if (online_only and this.is_online == false) or not FileExist(this.jsonPath)
            throw Error("The json is not updated or do not exist. Turn online_only to false or use GetInfo() first.")

        json := this.GetJsonMap()

        loop json.Length{
            if json[A_Index]["prerelease"]
                continue
            return json[A_Index]["tag_name"]
        }
    }

/*
    Returns True or 1 if "current_version" is equal or higher than the latest release tag_name.
    set "pre_release" to false to not get a release tagged as "prerelease".

    if "online_only" is set to true, GetInfo() must have been called at least once before it, else
    the json file will be used even if it is from another session as long as it exists.

    This is just a Qol method, the same could be achieved with:
    "VerCompare(current_version, GetLatestRelease()["tag_name"]) >= 0"
*/
    IsUpToDate(current_version, pre_release := false, online_only := false){
        return VerCompare(current_version, this.GetLatestReleaseVersion(pre_release, online_only)) >= 0
    }


    Update(install_path, release := this.GetLatestRelease(), auto_start := true){
        Download(release["download_url"], A_Temp "\temp_" release["exe_name"])
        install_bat := BatWrite(A_Temp "\install_bat.bat")
        install_bat.TimeOut(1)
        install_bat.MoveFile(install_path "\" release["exe_name"], A_Temp "\old_" release["exe_name"])
        install_bat.MoveFile(A_Temp "\temp_" release["exe_name"], install_path "\" release["exe_name"])
        install_bat.TimeOut(1)
        if auto_start
            install_bat.Start(install_path "\" release["exe_name"])

        Run(install_bat.path, , "Hide")
        ExitApp()
    }


    _GetReleaseMap(release_map){
        release := Map()
            release["id"]               := release_map["id"]
            release["assets_url"]       := release_map["assets_url"]
            release["upload_url"]       := release_map["upload_url"]
            release["html_url"]         := release_map["html_url"]
            release["node_id"]          := release_map["node_id"]
            release["target_commitish"] := release_map["target_commitish"]
            release["draft"]            := release_map["draft"]
            release["prerelease"]       := release_map["prerelease"]
            release["created_at"]       := release_map["created_at"]
            release["name"]             := release_map["name"]
            release["tag_name"]         := release_map["tag_name"]
            release["published_at"]     := release_map["published_at"]
            release["exe_name"]         := release_map["assets"][1]["name"]
            release["file_size"]        := release_map["assets"][1]["size"]
            release["download_count"]   := release_map["assets"][1]["download_count"]
            release["created_at"]       := release_map["assets"][1]["created_at"]
            release["updated_at"]       := release_map["assets"][1]["updated_at"]
            release["download_url"]     := release_map["assets"][1]["browser_download_url"]
            release["assets_id"]        := release_map["assets"][1]["id"]
            release["assets_node_id"]   := release_map["assets"][1]["node_id"]
            release["assets_label"]     := release_map["assets"][1]["label"]
            release["content_type"]     := release_map["assets"][1]["content_type"]
            release["state"]            := release_map["assets"][1]["state"]
            release["tarball_url"]      := release_map["tarball_url"]
            release["zipball_url"]      := release_map["zipball_url"]
            release["update_message"]   := release_map["body"]

            return release
    }

    /*
    Reads the json file, converts to a Array with Maps, and returns it.
    */
    GetJsonMap(){
        jao := FileRead(this.jsonPath, "UTF-8")
        return _Jxon_Load(&jao)
    }
}


; --------Dependencies------------
/*
Author: TheBrunoCA
Github: https://github.com/TheBrunoCA
Original repository: https://github.com/TheBrunoCA/Bruno-Functions
*/

/*
Downloads the page's content and returns it. Not Async.
@Param p_url The url for the page.
@Return The page's content.
*/
_GetPageContent(p_url)
{
    page := ComObject("MSXML2.XMLHTTP.6.0")
    page.Open("GET", p_url, true)

    loop 10 {
        try {
            page.Send()
            while (page.readyState != 4)
            {
                Sleep(50)
            }
            break
        }
        catch Error as e {
            if InStr(e.Message, "(0x80070005)") {
                sleep 50
                continue
            }
            else
                throw e
        }
    }
    return page.ResponseText
}

_FileOverwrite(text, file_pattern){
    try{
        FileDelete(file_pattern)
    } catch Error as e{
        if e.Message == "Parameter #1 of FileDelete is invalid."
            throw Error("Parameter #1 of _FileOverwrite is invalid.")
    }
    try{
        FileAppend(text, file_pattern, "UTF-8")
    }
}

/*
AHK v2 - https://github.com/TheArkive/JXON_ahk2
MIT License
Copyright (c) 2021 TheArkive
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

originally posted by user coco on AutoHotkey.com
https://github.com/cocobelgica/AutoHotkey-JSON
*/

_Jxon_Load(&src, args*) {
    key := "", is_key := false
    stack := [tree := []]
    next := '"{[01234567890-tfn'
    pos := 0

    while ((ch := SubStr(src, ++pos, 1)) != "") {
        if InStr(" `t`n`r", ch)
            continue
        if !InStr(next, ch, true) {
            testArr := StrSplit(SubStr(src, 1, pos), "`n")

            local ln := testArr.Length
            col := pos - InStr(src, "`n", , -(StrLen(src) - pos + 1))

            msg := Format("{}: line {} col {} (char {})"
                , (next == "") ? ["Extra data", ch := SubStr(src, pos)][1]
                : (next == "'") ? "Unterminated string starting at"
                    : (next == "\") ? "Invalid \escape"
                    : (next == ":") ? "Expecting ':' delimiter"
                    : (next == '"') ? "Expecting object key enclosed in double quotes"
                    : (next == '"}') ? "Expecting object key enclosed in double quotes or object closing '}'"
                    : (next == ",}") ? "Expecting ',' delimiter or object closing '}'"
                    : (next == ",]") ? "Expecting ',' delimiter or array closing ']'"
                    : ["Expecting JSON value(string, number, [true, false, null], object or array)"
                        , ch := SubStr(src, pos, (SubStr(src, pos) ~= "[\]\},\s]|$") - 1)][1]
                , ln, col, pos)

            throw Error(msg, -1, ch)
        }

        obj := stack[1]
        is_array := (obj is Array)

        if i := InStr("{[", ch) { ; start new object / map?
            val := (i = 1) ? Map() : Array()	; ahk v2

            is_array ? obj.Push(val) : obj[key] := val
            stack.InsertAt(1, val)

            next := '"' ((is_key := (ch == "{")) ? "}" : "{[]0123456789-tfn")
        } else if InStr("}]", ch) {
            stack.RemoveAt(1)
            next := (stack[1] == tree) ? "" : (stack[1] is Array) ? ",]" : ",}"
        } else if InStr(",:", ch) {
            is_key := (!is_array && ch == ",")
            next := is_key ? '"' : '"{[0123456789-tfn'
        } else { ; string | number | true | false | null
            if (ch == '"') { ; string
                i := pos
                while i := InStr(src, '"', , i + 1) {
                    val := StrReplace(SubStr(src, pos + 1, i - pos - 1), "\\", "\u005C")
                    if (SubStr(val, -1) != "\")
                        break
                }
                if !i ? (pos--, next := "'") : 0
                    continue

                pos := i ; update pos

                val := StrReplace(val, "\/", "/")
                val := StrReplace(val, '\"', '"')
                    , val := StrReplace(val, "\b", "`b")
                    , val := StrReplace(val, "\f", "`f")
                    , val := StrReplace(val, "\n", "`n")
                    , val := StrReplace(val, "\r", "`r")
                    , val := StrReplace(val, "\t", "`t")

                i := 0
                while i := InStr(val, "\", , i + 1) {
                    if (SubStr(val, i + 1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
                        continue 2

                    xxxx := Abs("0x" . SubStr(val, i + 2, 4)) ; \uXXXX - JSON unicode escape sequence
                    if (xxxx < 0x100)
                        val := SubStr(val, 1, i - 1) . Chr(xxxx) . SubStr(val, i + 6)
                }

                if is_key {
                    key := val, next := ":"
                    continue
                }
            } else { ; number | true | false | null
                val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$", , pos) - pos)

                if IsInteger(val)
                    val += 0
                else if IsFloat(val)
                    val += 0
                else if (val == "true" || val == "false")
                    val := (val == "true")
                else if (val == "null")
                    val := ""
                else if is_key {
                    pos--, next := "#"
                    continue
                }

                pos += i - 1
            }

            is_array ? obj.Push(val) : obj[key] := val
            next := obj == tree ? "" : is_array ? ",]" : ",}"
        }
    }

    return tree[1]
}

_Jxon_Dump(obj, indent := "", lvl := 1) {
    if IsObject(obj) {
        If !(obj is Array || obj is Map || obj is String || obj is Number)
            throw Error("Object type not supported.", -1, Format("<Object at 0x{:p}>", ObjPtr(obj)))

        if IsInteger(indent)
        {
            if (indent < 0)
                throw Error("Indent parameter must be a postive integer.", -1, indent)
            spaces := indent, indent := ""

            Loop spaces ; ===> changed
                indent .= " "
        }
        indt := ""

        Loop indent ? lvl : 0
            indt .= indent

        is_array := (obj is Array)

        lvl += 1, out := "" ; Make #Warn happy
        for k, v in obj {
            if IsObject(k) || (k == "")
                throw Error("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", ObjPtr(obj)) : "<blank>")

            if !is_array ;// key ; ObjGetCapacity([k], 1)
                out .= (ObjGetCapacity([k]) ? _Jxon_Dump(k) : escape_str(k)) (indent ? ": " : ":") ; token + padding

            out .= _Jxon_Dump(v, indent, lvl) ; value
                . (indent ? ",`n" . indt : ",") ; token + indent
        }

        if (out != "") {
            out := Trim(out, ",`n" . indent)
            if (indent != "")
                out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent) + 1)
        }

        return is_array ? "[" . out . "]" : "{" . out . "}"

    } Else If (obj is Number)
        return obj
    Else ; String
        return escape_str(obj)

    escape_str(obj) {
        obj := StrReplace(obj, "\", "\\")
        obj := StrReplace(obj, "`t", "\t")
        obj := StrReplace(obj, "`r", "\r")
        obj := StrReplace(obj, "`n", "\n")
        obj := StrReplace(obj, "`b", "\b")
        obj := StrReplace(obj, "`f", "\f")
        obj := StrReplace(obj, "/", "\/")
        obj := StrReplace(obj, '"', '\"')

        return '"' obj '"'
    }
}


class _BatWrite {
    __New(p_bat_path, p_append := false) {
        dir := StrSplit(p_bat_path, "\")
        dir.Pop()
        tdir := ""
        for i, w in dir{
            tdir .= w . "\"
        }
        dir := tdir
        if DirExist(dir) == ""
            DirCreate(dir)

        ext := StrSplit(p_bat_path, ".")
        if ext[ext.Length] != "bat"
            p_bat_path .= ".bat"

        this.path := p_bat_path
        if p_append == false {
            if FileExist(this.path) != ""
                FileDelete(this.path)
        }

        FileAppend("@CHCP 1252 >NUL`n", this.path)
    }

    /*
    Deletes the bat itself. It will work after this. But without the encoding config.
    */
    DeleteSelf() {
        if FileExist(this.path) != ""
            FileDelete(this.path)
    }

    AddEncoding() {
        FileAppend("@CHCP 1252 >NUL`n", this.path)
    }

    /*
    Moves a file.
    */
    MoveFile(p_from, p_to) {
        w := "
        (
        MOVE /Y "{1}" "{2}"

        )"

        w := Format(w, p_from, p_to)

        FileAppend(w, this.path)
    }

    /*
    Deletes a file.
    */
    DeleteFile(p_file){
        w := "
        (
        DEL "{1}"

        )"

        w := Format(w, p_file)

        FileAppend(w, this.path)
    }

    /*
    Its a batch equivalent of Run.
    */
    Start(p_path){
        w := "
        (
        START "" "{1}"

        )"

        w := Format(w, p_path)

        FileAppend(w, this.path)
    }

    /*
    Its a batch equivalent of sleep.
    */
    TimeOut(p_seconds){
        w := "
        (
        TIMEOUT /T {1} /NOBREAK

        )"

        w := Format(w, p_seconds)

        FileAppend(w, this.path)
    }

    /*
    Deletes the last line of command.
    */
    DeleteLastLine(){
        local file := FileRead(this.path)
        if file == ""
            return
        file := StrSplit(file, "`n")
        
        for i in file.Length{
            last := file.Pop()
            if last != ""
                break
        }
        local ret := ""
        for i, w in file{
            ret .= w . "`n"
        }
        try{
            FileDelete(this.path)
        }
        FileAppend(ret, this.path)
    }

    /*
     Creates a shortcut of something somewhere.
    */
    CreateShortcut(p_from, p_to, p_type := "Powershell"){
        if p_type != "Powershell" && p_type != "Mklink"
            throw Error("p_type can only be `"Powershell`" or `"Mklink`"!")
        ext := StrSplit(p_to, ".")
        if ext[ext.Length] != "lnk"
            p_to .= ".lnk"

        switch p_type {
            case "Powershell":
                {
                    w := "
                    (
                    powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('{1}');$s.TargetPath='{2}';$s.Save()"
                    
                    )"
                    w := Format(w, p_to, p_from)
                    FileAppend(w, this.path)
                }
            default:
                {
                    w := "
                    (
                    mklink "{1}" "{2}"
                    
                    )"
                    w := Format(w, p_to, p_from)
                    FileAppend(w, this.path)
                }
        }
    }

    /*
    Schedules something to run on logon. It works but the bat needs to be run as admin.
    */
    ScheduleOnLogon(task_name, task_path, run_level := "Limited"){
        w := "
        (
        schtasks /Create /RL "{3}" /RU "NT AUTHORITY\SYSTEM" /SC ONLOGON /TN "{1}" /TR "{2}"

        )"

        w := Format(w, task_name, task_path, run_level)

        FileAppend(w, this.path)
    }

    DeleteSchedule(task_name){
        w := "
        (
        schtasks /Delete /TN "{1}"

        )"

        w := Format(w, task_name)

        FileAppend(w, this.path)
    }
}