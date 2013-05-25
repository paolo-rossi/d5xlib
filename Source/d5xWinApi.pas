(*
Copyright (c) 2013 Darian Miller

All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so, provided that the above copyright notice(s) and this permission notice
appear in all copies of the Software and that both the above copyright notice(s) and this permission notice appear in supporting documentation.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE BE
LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER
IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall not be used in advertising or otherwise to promote the sale, use or other
dealings in this Software without prior written authorization of the copyright holder.
*)

unit d5xWinApi;

interface
uses
  Windows;

  //Waits for signals to fire while processing pending message queue
  function WaitWithMessageLoop(const pHandleToWaitOn:THandle; const pMaxTimeToWaitMS:Integer=INFINITE):Boolean;


implementation
uses
  Messages;


function WaitWithMessageLoop(const pHandleToWaitOn:THandle; const pMaxTimeToWaitMS:Integer=INFINITE):Boolean;
const
  WaitForAll = False;
  InitialTimeOutMS = 0;
  IterateTimeOutMS = 200;
var
  vTimeSpentWaitingMS:Integer;
  vReturnVal:DWord;
  Msg:TMsg;
  H:THandle;
begin
  H := pHandleToWaitOn;

  // MsgWaitForMultipleObjects doesn't return with already signaled objects
  // Check first
  vReturnVal := WaitForSingleObject(H, InitialTimeOutMS);
  if (vReturnVal = WAIT_OBJECT_0) then
  begin
    Result := True;
    Exit;
  end;

  vTimeSpentWaitingMS := 0;
  while True do
  begin

    if (pMaxTimeToWaitMS <> INFINITE) and (vTimeSpentWaitingMS >= pMaxTimeToWaitMS) then
    begin
      Result := False;
      Exit;
    end;

    //Also due to the way MsgWaitForMultipleObjects operates,
    //process pending messages first (as existing pending messages apparently won't signal)
    while PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
    begin
      if Msg.Message = WM_QUIT then
      begin
        Result := False;
        Exit;
      end;
      TranslateMessage(Msg);
      DispatchMessage(Msg);

      vReturnVal := WaitForSingleObject(H, 0);
      if(vReturnVal = WAIT_OBJECT_0) then
      begin
        Result := True;
        Exit;
      end;
    end;


    // Now we've dispatched all the messages in the queue
    // use MsgWaitForMultipleObjects to either tell us there are
    // more messages to dispatch, or that our object has been signalled.
    vReturnVal := MsgWaitForMultipleObjects(1, H, WaitForAll, IterateTimeOutMS, QS_ALLINPUT);

    if (vReturnVal = WAIT_OBJECT_0) then
    begin
      // The event was signaled
      Result := True;
      Exit;
    end
    else if (vReturnVal = WAIT_OBJECT_0 + 1) then
    begin
      // New messages have come that need to be dispatched
      Continue;
    end
    else if (vReturnVal = WAIT_TIMEOUT) then
    begin
      // We hit our time limit, continue with the loop
      Inc(vTimeSpentWaitingMS, IterateTimeOutMS);
      Continue;
    end
    else
    begin
      // Something else happened
      Result := False;
      Exit;
    end;
  end;
end;


end.