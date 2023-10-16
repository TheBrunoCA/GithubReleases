#Requires AutoHotkey v2.0+
#Warn All, StdOut

#Include .\Lib\Logfy.ahk

class GithubReleases2{
    __New(user, repo, custom_json_path?, log_path?, log_append := false) {
        this.user                   := user
        this.repo                   := repo
        this.user_repo              := this.user "/" this.repo

        this.__default_log_path     := "{1}\{2}-{3}-log.txt"
        this.__default_log_path     := Format(this.__default_log_path, A_Temp, this.user, this.repo)
        this.log                    := IsSet(log_path) ? Logfy(log_path, log_append) : Logfy(this.__default_log_path, log_append)


        this.url                    := "https://api.github.com/repos/{1}/{2}/releases"
        this.url                    := Format(this.url, this.user, this.repo)

        this.__default_json_path    := "{1}\{2}-{3}.json"
        this.__default_json_path    := Format(this.__default_json_path, A_Temp, this.user, this.repo)
        this.json_path              := IsSet(custom_json_path) ? custom_json_path : this.__default_json_path


        this.is_json_uptodate       := false

        if not this.HasJson()
            this.UpdateJson()

        this.log.log(Format("Finished loading git {1}.", this.user_repo))
    }

    json_path[*]{
        get => this.__json_path
        set => InStr(value, ".json") ? this.__json_path := value : this.__json_path := value ".json"
    }

    /**
     * 
     * @returns {true if json exists, else false} 
     */
    HasJson(){
        this.log.log(Format("{1} on {2} was called.", A_ThisFunc, this.user_repo))
        local exists := FileExist(this.json_path) ? true : false
        this.log.log(Format("{1} on {2} returned {3}", A_ThisFunc, this.user_repo, exists ? "True" : "False"))
        return exists
    }

    /**
     * Try to get the updated json file from Github
     * @returns {true if succesful, else false} 
     */
    UpdateJson(){
        this.log.log(Format("{1} on {2} was called.", A_ThisFunc, this.user_repo))
        local json := _GetPageContent(this.url)
        if InStr(json, this.user) and InStr(json, this.repo){
            try{
                _FileOverwrite(json, this.json_path)
                this.log.log(Format("{1} on {2} updated the Json", A_ThisFunc, this.user_repo))
                return this.is_json_uptodate := true
            } catch Error as e{
                this.log.log(Format("{1} on {2} failed to update the Json due to the following error`n{2}`n"
                , A_ThisFunc, this.user_repo, e.Message))
            }
        }
        if this.HasJson(){
            try{
                FileDelete(this.json_path)
                this.log.log(Format("{1} on {2} deleted the Json", A_ThisFunc, this.user_repo))
            } catch Error as e{
                this.log.log(Format("{1} on {2} failed to delete the Json due to the following error`n{2}`n"
                , A_ThisFunc, this.user_repo, e.Message))
            }
        }
        this.log.log(Format("{1} on {2} failed to update the Json", A_ThisFunc, this.user_repo))
        return this.is_json_uptodate := false
    }

    /**
     * Transforms the json file to a Map()
     * @returns {the json's Map if succesful, else returns false} 
     */
    GetJsonMap(){
        this.log.log(Format("{1} on {2} was called.", A_ThisFunc, this.user_repo))
        if not this.AssertJson()
            return

        try{
            local json := FileRead(this.json_path)
            this.log.log(Format("{1} on {2} Successfully retrieved the Json Map", A_ThisFunc, this.user_repo))
            return _Jxon_Load(&json)
        } catch Error as e{
            this.log.log(Format("{1} on {2} failed to retrieve the Json Map due to the following error`n{2}`n"
            , A_ThisFunc, this.user_repo, e.Message))
            return false
        }
        
    }


    AssertJson(){
        this.log.log(Format("{1} on {2} was called.", A_ThisFunc, this.user_repo))
        if not this.HasJson(){
            if not this.UpdateJson(){
                this.log.log(Format("{1} on {2} failed to assert the Json file.", A_ThisFunc, this.user_repo))
                return this.is_json_uptodate := false
            }
        }
        this.log.log(Format("{1} on {2} Successfully asserted the Json Map", A_ThisFunc, this.user_repo))
        return this.is_json_uptodate := true
    }


    GetReleasesList(pre_release := false){
        this.log.log(Format("{1} on {2} was called.", A_ThisFunc, this.user_repo))
        if not this.AssertJson()
            return false

        local releases := []
        if not json_map := this.GetJsonMap()
            return false

        for index, release_map in json_map{
            local r := Release(release_map)
            if r.is_prerelease and not pre_release
                continue
            releases.Push(r)
        }
        if not releases.Has(1){
            this.log.log(Format("{1} on {2} did not find any release with pre_release {3}."
            , A_ThisFunc, this.user_repo, pre_release ? "True" : "False"))
            return false
        }

        this.log.log(Format("{1} on {2} Successfully returned {3} release(s).", A_ThisFunc, this.user_repo, releases.Length))
        return releases
    }


    GetLatestRelease(pre_release := false){
        this.log.log(Format("{1} on {2} was called.", A_ThisFunc, this.user_repo))
        if not this.AssertJson()
            return false

        if not json_map := this.GetJsonMap()
            return false

        for index, release_map in json_map{
            local r := Release(release_map)
            if r.is_prerelease and not pre_release
                continue
            this.log.log(Format("{1} on {2} Successfully returned the latest release.", A_ThisFunc, this.user_repo))
            return r
        }
        this.log.log(Format("{1} on {2} did not find any release with pre_release {3}."
            , A_ThisFunc, this.user_repo, pre_release ? "True" : "False"))
        return false
    }
}


class Release{
    __New(release_jxon) {
        this.assets             := Assets(release_jxon["assets"])
        this.assets_url         := release_jxon.Has("assets_url") ? release_jxon["assets_url"] : ""
        this.author             := release_jxon.Has("author") ? User(release_jxon["author"]) : ""
        this.body               := release_jxon.Has("body") ? release_jxon["body"] : ""
        this.created_at         := release_jxon.Has("created_at") ? release_jxon["created_at"] : ""
        this.is_draft           := release_jxon.Has("draft") ? release_jxon["draft"] : ""
        this.html_url           := release_jxon.Has("html_url") ? release_jxon["html_url"] : ""
        this.id                 := release_jxon.Has("id") ? release_jxon["id"] : ""
        this.mentions_count     := release_jxon.Has("mentions_count") ? release_jxon["mentions_count"] : ""
        this.name               := release_jxon.Has("name") ? release_jxon["name"] : ""
        this.node_id            := release_jxon.Has("node_id") ? release_jxon["node_id"] : ""
        this.is_prerelease      := release_jxon.Has("prerelease") ? release_jxon["prerelease"] : ""
        this.published_at       := release_jxon.Has("published_at") ? release_jxon["published_at"] : ""
        this.reactions          := release_jxon.Has("reactions") ? Reactions(release_jxon["reactions"]) : ""
        this.tag_name           := release_jxon.Has("tag_name") ? release_jxon["tag_name"] : ""
        this.version            := this.tag_name
        this.tarball_url        := release_jxon.Has("tarball_url") ? release_jxon["tarball_url"] : ""
        this.target_commitish   := release_jxon.Has("target_commitish") ? release_jxon["target_commitish"] : ""
        this.upload_url         := release_jxon.Has("upload_url") ? release_jxon["upload_url"] : ""
        this.url                := release_jxon.Has("url") ? release_jxon["url"] : ""
        this.zipball_url        := release_jxon.Has("zipball_url") ? release_jxon["zipball_url"] : ""
    }

    created_at[*]{
        get => this.__created_at
        set => this.__created_at := ConvertGitTimeToAhkTime(value)
    }

    published_at[*]{
        get => this.__published_at
        set => this.__published_at := ConvertGitTimeToAhkTime(value)
    }
}

Class Assets{
    __New(assets_map) {
        this.list             := []
        local map
        for index, map in assets_map{
            this.list.Push(Asset(map))
        }
    }

    GetByName(exe_name){
        local asset
        for index, asset in this.list{
            if not asset.HasProp("name")
                continue
            
            if asset.name == exe_name
                return asset
        }
        return false
    }
}

class Asset{
    __New(asset_map) {
        this.browser_download_url   := asset_map.Has("browser_download_url") ? asset_map["browser_download_url"] : ""
        this.content_type           := asset_map.Has("content_type") ? asset_map["content_type"] : ""
        this.created_at             := asset_map.Has("created_at") ? asset_map["created_at"] : ""
        this.download_count         := asset_map.Has("download_count") ? asset_map["download_count"] : ""
        this.id                     := asset_map.Has("id") ? asset_map["id"] : ""
        this.label                  := asset_map.Has("label") ? asset_map["label"] : ""
        this.name                   := asset_map.Has("name") ? asset_map["name"] : ""
        this.node_id                := asset_map.Has("node_id") ? asset_map["node_id"] : ""
        this.size                   := asset_map.Has("size") ? asset_map["size"] : ""
        this.updated_at             := asset_map.Has("updated_at") ? asset_map["updated_at"] : ""
        this.uploader               := asset_map.Has("uploader") ? User(asset_map["uploader"]) : ""
        this.url                    := asset_map.Has("url") ? asset_map["url"] : ""
    }
    created_at[*]{
        get => this.__created_at
        set => this.__created_at := ConvertGitTimeToAhkTime(value)
    }

    updated_at[*]{
        get => this.__updated_at
        set => this.__updated_at := ConvertGitTimeToAhkTime(value)
    }


}

class User{
    __New(user_map) {
        this.avatar_url         := user_map.Has("avatar_url") ? user_map["avatar_url"] : ""
        this.events_url         := user_map.Has("events_url") ? user_map["events_url"] : ""
        this.followers_url      := user_map.Has("followers_url") ? user_map["followers_url"] : ""
        this.following_url      := user_map.Has("following_url") ? user_map["following_url"] : ""
        this.gists_url          := user_map.Has("gists_url") ? user_map["gists_url"] : ""
        this.gravatar_id        := user_map.Has("gravatar_id") ? user_map["gravatar_id"] : ""
        this.html_url           := user_map.Has("html_url") ? user_map["html_url"] : ""
        this.id                 := user_map.Has("id") ? user_map["id"] : ""
        this.login              := user_map.Has("login") ? user_map["login"] : ""
        this.node_id            := user_map.Has("node_id") ? user_map["node_id"] : ""
        this.organizations_url  := user_map.Has("organizations_url") ? user_map["organizations_url"] : ""
        this.received_events_url:= user_map.Has("received_events_url") ? user_map["received_events_url"] : ""
        this.repos_url          := user_map.Has("repos_url") ? user_map["repos_url"] : ""
        this.is_site_admin      := user_map.Has("site_admin") ? user_map["site_admin"] : ""
        this.starred_url        := user_map.Has("starred_url") ? user_map["starred_url"] : ""
        this.subscriptions_url  := user_map.Has("subscriptions_url") ? user_map["subscriptions_url"] : ""
        this.type               := user_map.Has("type") ? user_map["type"] : ""
        this.url                := user_map.Has("url") ? user_map["url"] : ""
    }
}

class Reactions{
    __New(reactions_map) {
        this.plus_one := reactions_map.Has("+1") ? reactions_map["+1"] : ""
        this.minus_one := reactions_map.Has("-1") ? reactions_map["-1"] : ""
        this.confused := reactions_map.Has("confused") ? reactions_map["confused"] : ""
        this.eyes := reactions_map.Has("eyes") ? reactions_map["eyes"] : ""
        this.heart := reactions_map.Has("heart") ? reactions_map["heart"] : ""
        this.hooray := reactions_map.Has("hooray") ? reactions_map["hooray"] : ""
        this.laugh := reactions_map.Has("laugh") ? reactions_map["laugh"] : ""
        this.rocket := reactions_map.Has("rocket") ? reactions_map["rocket"] : ""
        this.total_count := reactions_map.Has("total_count") ? reactions_map["total_count"] : ""
        this.url := reactions_map.Has("url") ? reactions_map["url"] : ""
    }
}

ConvertGitTimeToAhkTime(git_time){
    local v         := StrSplit(git_time, "T")
    local date      := StrSplit(v[1], "-")
    local time      := StrSplit(RTrim(v[2], "Z"), ":")
    local year      := date[1]
    local month     := date[2]
    local day       := date[3]
    local hour      := time[1]
    local minute    := time[2]
    local second    := time[3]
    local datetime  := year month day hour minute second

    return datetime
}

ConvertAhkTimeToGitTime(ahk_time){
    local year      := SubStr(ahk_time, 1, 4)
    local month     := SubStr(ahk_time, 5, 2)
    local day       := SubStr(ahk_time, 7, 2)
    local hour      := SubStr(ahk_time, 9, 2)
    local minute    := SubStr(ahk_time, 11, 2)
    local second    := SubStr(ahk_time, 13, 2)
    local datetime  := "{1}-{2}-{3}T{4}:{5}:{6}Z"
    datetime        := Format(datetime, year, month, day, hour, minute, second)

    return datetime
}


/*
Downloads the page's content and returns it. Not Async.
@Param p_url The url for the page.
@Return The page's content.
*/
_GetPageContent(p_url)
{
    local page := ComObject("MSXML2.XMLHTTP.6.0")
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