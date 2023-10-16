class BatWrite {
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