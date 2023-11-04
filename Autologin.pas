unit AutoLogin;

interface

uses
  SysUtils, Classes;

type
  AccountsArr = array of string;

function Login(user: string; password: string; AccountControl: TL2Control): boolean;

Implementation

const
    // I use numbers to SendKey, 'BackSpace' in some reason not worked
    BackSpace = 8;
    Enter = 13;
    Tab = 9;

    // 60 seconds before offline status detectes
    OfflineTimerThreshold = '00:01:00';

    // Delay to confirm license, server, etc... increase or decrease this
    // values depending on your PC/Network state
    EnterTextDealy = 2500;

    // Wait online iterations, after gamestart and run client,
    // 30 iterations = wait maximum 30 seconds
    WaitIterations = 30;

    // How often check do we online, after trying to login
    LoggedInCheckInterval = 3000;
    LoggedInCheckIterations = 15; // 15 * 3000 = about 45 seconds

    // If tried to login 5 times and all attempts failed, stop script
    // basically is sort of protection, to run too many game clients...
    MaxFaluresInARow = 5;

    // How often to check lsOnline in AutoLoginWithMonitoring procedure, 15 sec.
    OnlineCheckInterval = 15000;

// Wrapper to send keys with delay
procedure UseKey(key: word; AccountControl: TL2Control);
begin
    AccountControl.Delay(EnterTextDealy);
    AccountControl.UseKey(key);
end;

// Function to wait while status will be online
// TODO: instead itreation we can use timer based solution
function WaitOnline(AccountControl: TL2Control): boolean;
var
    i: integer;
begin
    for i := 0 to WaitIterations do
    begin
        if (AccountControl.Status <> lsOnline) then UseKey(Enter, AccountControl) else break;
    end;
    if  AccountControl.Status = lsOnline then 
        AccountControl.Msg('Autologin', 'Succesefully loaded character');
    Result := AccountControl.Status = lsOnline;
end;

// Core login functionality
function Login;
var
    i, j: integer;
begin
    if (AccountControl.Status = lsOnline) then
    begin
        AccountControl.Msg('Already online!', 'Login');
        Result := True;
    end;

    for i := 0 to LoggedInCheckIterations do
    begin
        if (AccountControl.GameWindow <> 0) and (AccountControl.AuthLogin(user, password)) then  begin
            break;
        end
        else
            AccountControl.Delay(LoggedInCheckInterval)
    end;

    for i := 0 to 3 do begin
        for j := 0 to 3 do
            UseKey(Enter, AccountControl); // TODO: This can be replaced to packet based solution?

        // We retunr true only when gamestart and status is online
        if AccountControl.GameStart() then
        begin
            AccountControl.Msg('Autologin', 'Waiting online...');
            Result := WaitOnline(AccountControl);
            break;
        end;
    end;
end;

BEGIN
END.
