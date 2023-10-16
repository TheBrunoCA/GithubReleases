downloadFile(url, filename, progress := true, overwrite := true, onCloseCallback := false){
    if not overwrite and FileExist(filename)
        return


    local file := StrSplit(filename, "\")
    file := file[file.Length]

    last_size := 0
    progressGui := Gui("AlwaysOnTop -Caption -Border", "Download em andamento")

    if onCloseCallback
        progressGui.OnEvent("Close", onCloseCallback)

    conLength := ""

    try{
        obj := ComObject("WinHttp.WinHttpRequest.5.1")
        obj.Open("HEAD", url)
        obj.Send()
        conLength := obj.GetResponseHeader("Content-Length")
    }

    addProgressBar := conLength != "" and progress

    progressName := progressGui.AddText(, "Baixando " file " de " url)

    if addProgressBar
        progressBar := progressGui.AddProgress("w500 BackgroundGray cGreen", 0)

    progressValue := progressGui.AddText("w300", "")
    progressDelta := progressGui.AddText("w300", "")
    progressGui.Show()
    SetTimer(__updateProgress, 20)
    currentSize := 0
    Download(url, filename)
    if IsSet(progressBar)
        progressBar.Value := 100
    SetTimer(__updateProgress, 0)
    progressValue.Value := "Finalizado"
    Sleep 1000
    progressGui.Destroy()
    return filename

        __updateProgress(){
            try{
                currentSize := FileGetSize(filename)
            }
            if addProgressBar
                progressBar.Value := Floor(currentSize / conLength * 100)

            delta_size := Floor((currentSize - last_size) / 1000 * 10)
            last_size := currentSize
            progressValue.Value := "Baixados: " Floor(currentSize/1000) " KB"
            
            if addProgressBar
                progressValue.Value .= " / " Floor(conLength / 1000) " KB"

            progressDelta.Value := "Velocidade: " delta_size / 1000 " MB/s"
        }
}