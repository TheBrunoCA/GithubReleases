class Logfy{
    __New(path?, append := true) {
        this.default_path := A_Temp "\" A_ScriptName "_log.txt"
        this.path := IsSet(path) ? path : this.default_path
        if not append
            try FileDelete(this.path)

        this.Log("`n`nStarted logging " A_ScriptName " ...")
    }

    path[*]{
        get => this.__path
        set => InStr(value, ".txt") ? this.__path := value : this.__path := value ".txt"
    }

    Log(message){
        local msg := "[{1}-{2}-{3} || {4}:{5}:{6}:{7} || {8}] - {9}`n"
        msg := Format(msg, A_Year, A_Mon, A_MDay, A_Hour, A_Min, A_Sec, A_MSec, A_ScriptName, message)
        FileAppend(msg, this.path)
    }
}