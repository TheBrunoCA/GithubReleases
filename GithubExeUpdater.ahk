#Include Lib\DownloadFile.ahk

Class GithubExeInstaller{
    static UpdateOther(installation_dir, exe_name, release_obj, show_download_progress := false){
        local asset := release_obj.assets.GetByName(exe_name)

        while ProcessExist(exe_name)
            ProcessClose(exe_name)

        local installation_full_path := installation_dir "\" exe_name

        if FileExist(installation_full_path)
            try FileDelete(installation_full_path)

        if show_download_progress{
            downloadFile(asset.browser_download_url, installation_full_path)
        }
        else
            Download(asset.browser_download_url, installation_full_path)
    }

    static UpdateSelf(){

    }
}

#Include ..\GithubReleases\GithubReleases2.ahk

path := A_AppData "\teste"
DirCreate(path)
github := GithubReleases2("TheBrunoCA", "FP-Extra", , A_ScriptDir)
GithubExeInstaller.UpdateOther(path, "FP-Extra.exe", github.GetLatestRelease(), true)
ExitApp()