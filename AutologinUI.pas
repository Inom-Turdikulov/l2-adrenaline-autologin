uses SysUtils, StdCtrls, Classes, Controls, Forms, Dialogs, SettingsModule, Autologin;

type
    TEvents = class(TObject)
        procedure OnClick(Sender: TObject);
    end;

    user = record
        Enabled: boolean;
        login: string;
        password: string;
        nickname: string;
    end;

const
    // Minimal delay to load login screen and try to login iterations, 20 sec.
    // Increase or decrease this values depending on your PC
    GameRunDealy = 20000;
    SettingsFile = 'Settings.ini';

var
    Frm: TForm;
    
    Events: TEvents;
    Reload: TButton;  // Reload button, to update enabled accounts
    Account: TBot; // Used to control specific account and log-in

    MaxAccounts: integer;
    NeedReload: boolean;

    Users: array of user;

    Accounts: AccountsArr;
    Settings: TSettings;
    CheckBoxes: array [0 .. 100] of TCheckbox;
    Edits: array [0 .. 100] of TEdit;

// External function to run executable program
function ShellExecuteW(hwnd: cardinal;
    lpOperation, lpFile, lpParameters, lpDirectory: pwidechar;
    nShowCmd: integer): cardinal;
    stdcall; external 'shell32.dll' Name 'ShellExecuteW';

// Load and split string (used to parse settings line)
procedure Split(Delimiter: char; Str: string; ListOfStrings: TStrings);
begin
    ListOfStrings.Clear;
    ListOfStrings.Delimiter := Delimiter;
    ListOfStrings.StrictDelimiter := True;
    ListOfStrings.DelimitedText := Str;
end;

procedure GenerateLoginUI();
var
    i, j: integer;
    AccountKey, AccountData: string;
    AccountStringList: TStringList;
    EditIndex: integer;
begin
    Events := TEvents.Create;

    AccountStringList := TStringList.Create;
    try
        { Generate form
          you can use additional parmeters here to control it's style
          Frm.BorderStyle := bsDialog;
          Frm.FormStyle := fsStayOnTop;
        }
        Frm := TForm.Create(nil);
        Frm.Caption := 'AutoLoginUI';
        Frm.Position := poScreenCenter;
        Frm.Width := 440;
        Frm.Height := 600;
        Frm.AlphaBlendValue := 200;
        Frm.AlphaBlend := True;
        Frm.AutoScroll := True;
        
        SetLength(Users, MaxAccounts);

        for i := 0 to MaxAccounts - 1 do
        begin
            AccountData := '';
            AccountStringList.Clear;
            
            AccountKey := 'account_' + IntToStr(i);
            AccountData := Settings.Load('main', AccountKey, AccountData);
            Split(',', AccountData, AccountStringList);

            Users[i].Enabled := (AccountStringList[0] = 'True');
            Users[i].login := AccountStringList[1];
            Users[i].password := AccountStringList[2];
            Users[i].nickname := AccountStringList[3];

            CheckBoxes[i] := TCheckbox.Create(Frm);
            CheckBoxes[i].Top := i * 25 + 10;
            CheckBoxes[i].left := 10;
            CheckBoxes[i].Parent := Frm;
            CheckBoxes[i].Checked := Users[i].Enabled;
            CheckBoxes[i].Name := 'account_' + IntToStr(i);
            CheckBoxes[i].OnClick := Events.OnClick;

            for j := 0 to 2 do
            begin
                EditIndex := i * 3 + j;
                Edits[EditIndex] := TEdit.Create(Frm);

                Edits[EditIndex].Top := i * 25 + 10;
                Edits[EditIndex].left := (j * 100) + 100;
                Edits[EditIndex].Width := 90;
                Edits[EditIndex].Parent := Frm;
                Edits[EditIndex].Text := AccountStringList[j + 1];
                Edits[EditIndex].OnChange := Events.OnClick;
                Edits[EditIndex].ReadOnly := True;

                if j <> 2 then Edits[EditIndex].PasswordChar := '*';
            end;
        end;
    finally
        AccountStringList.Free;
    end;

    //Frm.OnClose := Events.OnClose;
    Frm.Show;
end;

// Unload form
procedure OnFree;
begin
  Frm.Release();
end;

procedure TEvents.OnClick(Sender: TObject);
var
    S: string;
    i, j: integer;
    EditIndex: integer;
    Checkbox1: TCheckbox;
    DataStringList: TStringList;
begin
    Checkbox1 := TCheckbox(Sender);
    DataStringList := TStringList.Create;

    try
        S := '';
        S := Settings.Load('main', Checkbox1.Name, S);
        Engine.Msg('AugoLoginUI', 'Updating account ' + Checkbox1.Name);

        if Length(S) > 0 then
        begin
            Split(',', S, DataStringList);
            S := BoolToStr(Checkbox1.Checked);
            for i := 1 to DataStringList.Count - 1 do
            begin
                S := S + ',' + DataStringList[i];
            end;
            Settings.Save('main', Checkbox1.Name, S);
        end;
    finally
        DataStringList.Free;
    end;

    NeedReload := True;
end;

// Used to auto-login accounts
procedure ControlAccounts();
var
    i, j: integer;
    AccountStringList: TStringList;
    ToLoadAccount: string;
    ToLoadAccountOnline: boolean;
    ThreadUsers: array of user; // users which loaded in control thread
    AccountData: string;
    ClientPath: string;
begin
    NeedReload := True; // we need to load accounts on first iteration
    while True do
    begin
        // Reload accounts settings
        if NeedReload then
        begin
            NeedReload := False;
            SetLength(ThreadUsers, MaxAccounts);
            AccountStringList := TStringList.Create;
            ClientPath := Settings.Load('main', 'client_path', ClientPath);
            MaxAccounts := Settings.Load('main', 'max_accounts');

            try
                for i := 0 to MaxAccounts - 1 do
                begin
                    AccountStringList.Clear;
                    AccountData := Settings.Load('main', 'account_' + IntToStr(i), AccountData);
                    Split(',', AccountData, AccountStringList);
                    ThreadUsers[i].Enabled := AccountStringList[0] = 'True';
                    ThreadUsers[i].login := AccountStringList[1];
                    ThreadUsers[i].password := AccountStringList[2];
                    ThreadUsers[i].nickname := AccountStringList[3];
                end;
            finally
                AccountStringList.Free;
            end;
        end;

        // Cleanup - close clients which are not online not in accounts list
        for j := 0 to BotList.Count - 1 do
        begin
            account := TBot(BotList(j));

            if (Account.Control.Status <> lsonline) and
                (Account.Control.GameWindow > 0) then
                begin
                    Account.Control.GameClose;
                end;
        end;

        for i := low(ThreadUsers) to high(ThreadUsers) do
        begin
            if NeedReload then break; // settings changed need reload

            // Unload account and skip processing
            if not ThreadUsers[i].Enabled then begin
               if (BotList.ByName(ThreadUsers[i].Nickname, Account)) and
                  (Account.Control.status = lsonline) and
                  (Account.Control.GameWindow > 0) then
                  Account.Control.GameClose;
                  
               continue;
            end;

            // CheckBoxes accounts which need to be load
            ToLoadAccount := ThreadUsers[i].nickname;

            ToLoadAccountOnline := false;
            if (BotList.ByName(ToLoadAccount, Account)) and
                (Account.Control.status = lsonline) then begin
                    ToLoadAccountOnline := true;
            end
            else if (BotList.ByName(ToLoadAccount, Account)) and (Account.Control.GameWindow > 0) then Account.Control.GameClose;

            // Log-in
            if not ToLoadAccountOnline then
            begin
                // Rename accounts (fix specific loading issue by adrenaline,
                // if postions are in wrong order
                for j := 0 to BotList.Count - 1 do begin
                   account := TBot(BotList(j));
                   if (Account.Control.status <> lsonline) then
                     account.Newname := 'Имя_1';
                end;
                
                // Open new game client
                Engine.Msg('AugoLoginUI', 'Opening client at ' + ClientPath);
                ShellExecuteW(0, PChar('open'), PChar(ClientPath), nil,
                    PChar(ExtractFilePath(ClientPath)), 6);
                Engine.Delay(GameRunDealy);

                // Load account
                for j := 0 to BotList.Count - 1 do
                begin
                    account := TBot(BotList(j));
                    if (Account.Control.status <> lsonline) then
                    begin
                        Engine.Msg('loading', ThreadUsers[i].Nickname);
                        Login(ThreadUsers[i].login, ThreadUsers[i].password, Account.Control);
                        break;
                    end;
                end;

            end;
        end;
        Engine.delay(1000);
    end;
end;

// Used to intialize account login/password keys
procedure CheckAccounts();
var
    i: integer;
    AccountKey: string;
    AccountData: string;
begin
    for i := 0 to MaxAccounts - 1 do
    begin
        AccountKey := 'account_' + IntToStr(i);
        AccountData := '';
        AccountData := Settings.Load('main', AccountKey, AccountData);

        // If we detected empty account data need to update it
        if (AccountData = '') then
        begin
            Settings.Save('main', AccountKey, 'False,User,Password,Nickname');
        end;
    end;
end;

begin
    Settings.SetFile(Script.Path + SettingsFile);
    MaxAccounts := Settings.Load('main', 'max_accounts'); 
    CheckAccounts();
    Script.MainProc(@GenerateLoginUI);
    Script.NewThread(@ControlAccounts);

    // Here we can place any other code
    Engine.Msg('AutoLoginUI', format('Loaded %d accounts from settings', [MaxAccounts]));
    Delay(-1);
end.
