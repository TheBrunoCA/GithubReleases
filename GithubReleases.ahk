#Include <Bruno-Functions\ImportAllList>

Class GithubReleases{
    __New(user, repo) {
        this.user       := user
        this.repo       := repo
        this.url        := "https://api.github.com/repos/" this.user "/" this.repo "/releases"
        this.jsonPath   := A_Temp "\" this.user "-" this.repo ".json"
        this.is_online  := false
    }

    GetInfo(){
        response := GetPageContent(this.url)
        if response == "" or (not InStr(response, this.user) and not InStr(response, this.repo))
            throw Error("GetInfo failed to get information from the repository")

        FileOverwrite(response, this.jsonPath)
        this.is_online := true
    }

    GetListOfReleases(pre_release := false, online_only := false){
        if (online_only and this.is_online == false) or not FileExist(this.jsonPath)
            throw Error("The json is not updated or do not exist. Turn online_only to false or use GetInfo() first.")

        releases    := Array()
        json := this.GetJsonMap()

        loop json.Length{
            if json[A_Index]["prerelease"] and not pre_release
                continue

            releases.Push(this.GetReleaseMap(json[A_Index]))
        }
        if releases.Has(1)
            return releases

        throw Error("No release found.")
    }

    GetLatestRelease(pre_release := false, online_only := false){
        if (online_only and this.is_online == false) or not FileExist(this.jsonPath)
            throw Error("The json is not updated or do not exist. Turn online_only to false or use GetInfo() first.")

        json := this.GetJsonMap()

        loop json.Length{
            if json[A_Index]["prerelease"]
                continue
            return this.GetReleaseMap(json[A_Index])
        }
    }

    GetLatestReleaseDownloadUrl(pre_release := false, online_only := false){
        return this.GetLatestRelease(pre_release, online_only)["download_url"]
    }

    GetLatestReleaseVersion(pre_release := false, online_only := false){
        return this.GetLatestRelease(pre_release, online_only)["tag_name"]
    }

    IsUpToDate(current_version, pre_release := false, online_only := false){
        return VerCompare(current_version, this.GetLatestReleaseVersion(pre_release, online_only)) >= 0
    }

    GetReleaseMap(release_map){
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

    GetJsonMap(){
        jao := FileRead(this.jsonPath, "UTF-8")
        return Jxon_Load(&jao)
    }
}