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

As of May 2013, latest version available online at:
  https://github.com/darianmiller/d5xlib

D5X Win32/Win64 Ready
*)

{$I d5x.inc}
unit d5xThread;

interface

uses
  Classes,
  Windows,
  SysUtils,
  SyncObjs,
  d5xProcessLock;


type

  T5xThread = class;
  T5xNotifyThreadEvent = procedure(const pThread:T5xThread) of object;
  T5xExceptionEvent = procedure(const pSender:TObject; const pException:Exception) of object;


  T5xThreadState = (tsActive,
                    tsSuspended_NotYetStarted,
                    tsSuspended_ManuallyStopped,
                    tsSuspended_RunOnceCompleted,
                    tsSuspendPending_StopRequestReceived,
                    tsSuspendPending_RunOnceComplete,
                    tsTerminated);

  T5xThreadExecOption = (teRepeatRun,
                         teRunThenSuspend,
                         teRunThenFree);



  {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
  ///<summary>
  ///  A TThread that can be managed (started/stopped) externally
  ///</summary>
  ///<remarks>
  /// 2 main differences from TThread:
  ///   1):Descendants must override the Run() method.
  ///   2):Replace checking for Terminated in descendant Run loop with ThreadIsActive()
  ///</remarks>
  {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
  T5xThread = class(TThread)
  private
    fThreadState:T5xThreadState;
    fStateChangeLock:T5xProcessResourceLock;

    fExecOptionInt:Integer;
    fRequireCoinitialize:Boolean;

    fProgressTextToReport:String;
    fTrappedException:Exception;
    fOnException:T5xExceptionEvent;
    fOnRunCompletion:T5xNotifyThreadEvent;
    fOnReportProgress:TGetStrProc;

    fAbortableSleepEvent:TEvent;
    fResumeSignal:TEvent;
    fAwakeToFreeEvent:TEvent;

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private getter method, GetThreadState, is used to safely access the
    /// current thread state field which could be set at any time by
    /// this/another thread while being continuously read by this/another thread.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed by outside threads OR by Self within its own context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    function GetThreadState():T5xThreadState;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private getter method, GetExecOption, is used to read the current
    /// value of the ExecOption property
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed by outside threads OR by Self within its own context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    function GetExecOption():T5xThreadExecOption;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private setter method, SetExecOption, is used to write the current
    /// value of the ExecOption property in an atomic transaction
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed by outside threads OR by Self within its own context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure SetExecOption(const pVal:T5xThreadExecOption);
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private method, SuspendThread, is use to deactivate an active
    /// thread.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed by outside threads OR by Self within its own context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure SuspendThread(const pReason:T5xThreadState);
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private method, Sync_CallOnReportProgress, is meant to be protected
    /// within a Synchronize call to safely execute the optional
    /// OnReportProgress event within the main thread's context
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the main thread's context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure Sync_CallOnReportProgress();
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private method, Sync_CallOnRunCompletion, is meant to be protected
    /// within a Synchronize call to safely execute the optional OnRunCompletion
    /// event within the main thread's context
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the main thread's context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure Sync_CallOnRunCompletion();
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private method, Sync_CallOnException, is meant to be protected
    /// within a Synchronize call to safely execute the optional OnException
    /// event within the main thread's context
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the main thread's context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure Sync_CallOnException();
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private method, DoOnRunCompletion, sets up the call to properly
    /// execute the OnRunCompletion event via Syncrhonize.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure DoOnRunCompletion();
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private method, DoOnException, sets up the call to properly
    /// execute the OnException event via Syncrhonize.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure DoOnException();
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private method, CallSynchronize, calls the TThread.Synchronize
    /// method using the passed in TThreadMethod parameter.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure CallSynchronize(const pMethod:TThreadMethod);

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The private read-only property, ThreadState, calls GetThreadState to
    /// determine the current fThreadState
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is referenced by outside threads OR by Self within its own context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    property ThreadState:T5xThreadState read GetThreadState;
  protected
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The protected method, Execute, overrides TThread()'s abstract Execute
    /// method with common logic for handling thread descendants.  Instead of
    /// typical Delphi behavior of overriding Execute(), descendants should
    /// override the abstract Run() method and also check for ThreadIsActive
    /// versus checking for Terminated.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed by Self within its own context.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure Execute(); override;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The Virtual protected method, BeforeRun, is an empty stub versus an
    /// abstract method to allow for optional use by descendants.
    /// Typically, common Scatter/Gather type operations happen in Before/AfterRun
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure BeforeRun(); virtual;

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The virtual Abstract protected method, Run, should be overriden by descendant
    /// classes to perform work. The option (T5xThreadExecOption) passed to
    /// Start controls how Run is executed.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure Run(); virtual; ABSTRACT;

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The Virtual protected method, AfterRun, is an empty stub versus an
    /// abstract method to allow for optional use by descendants.
    /// Typically, common Scatter/Gather type operations happen in Before/AfterRun
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure AfterRun(); virtual;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The Virtual protected method, WaitForResume, is called when this thread
    /// is about to go inactive.  If overriding this method, descendants should
    /// peform desired work before the Inherited call.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure WaitForResume(); virtual;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The Virtual protected method, ThreadHasResumed, is called when this
    /// thread is returning to active state
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is called internally by Self within its own context.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure ThreadHasResumed(); virtual;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The Virtual protected method, ExternalRequestToStop, is an empty stub
    /// versus an abstract method to allow for optional use by descendants.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is referenced within the thread-safe GetThreadState call by either
    /// outside threads OR by Self within its own context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    function ExternalRequestToStop():Boolean; virtual;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The protected method, ReportProgress, is meant to be reused by
    /// descendant classes to allow for a built in way to communicate back to
    /// the main thread via a synchronized OnReportProgress event.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// Optional. This is called by Self within its own context and only by
    /// descendants.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure ReportProgress(const pAnyProgressText:String);
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The protected method, Sleep, is a replacement for windows.sleep
    /// intended to be use by descendant classes to allow for responding to
    /// thread suspension/termination if Sleep()ing.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// Optional. This is called by Self within its own context and only by
    /// descendants.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    procedure Sleep(const pSleepTimeMS:Integer);

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The protected property, ExecOption, is available for descendants to
    /// act in a hybrid manner (e.g. they can act as RepeatRun until a condition
    /// is hit and then set themselves to RunThenSuspend
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This property is referenced by outside threads OR by Self within its own
    /// context - which is the reason for InterlockedExchange in SetExecOption
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    property ExecOption:T5xThreadExecOption read GetExecOption write SetExecOption;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The protected property, RequireCoinitialize, is available for
    /// descendants as a flag to execute CoInitialize() before the thread Run
    /// loop and CoUnitialize() after the thread Run loop.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This property is referenced by Self within its own context and should
    /// be set once during Creation (as it is referenced before the BeforeRun()
    /// event so the only time to properly set this is in the constructor)
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    property RequireCoinitialize:Boolean read fRequireCoinitialize write fRequireCoinitialize;
  public
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// Public constructor for T5xThread, a descendant of TThread.
    /// Note: This constructor differs from TThread as all of these threads are
    /// started suspended by default.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the calling thread's context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    constructor Create();
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// Public destructor for T5xThread, a descendant of TThread.
    /// Note: This will automatically terminate/waitfor thread as needed
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed either within the calling thread's context
    /// OR within the threads context if auto-freeing itself
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    destructor Destroy(); override;

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The public method, Start, is used to activate the thread to begin work.
    /// All T5xThreads are created in suspended mode and must be activated to do
    /// any work.
    ///
    /// Note: By default, the descendant's 'Run' method is continuously executed
    /// (BeforeRun, Run, AfterRun is performed in a loop) This can be overriden
    /// by overriding the pExecOption default parameter
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the calling thread's context either directly
    /// OR during a Destroy if the thread is released but never started (Which
    /// temporarily starts the thread in order to properly shut it down.)
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    function Start(const pExecOption:T5xThreadExecOption=teRepeatRun):Boolean;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The public method, Stop, is a thread-safe way to deactivate a running
    /// thread.  The thread will continue operation until it has a chance to
    /// check the active status.
    /// Note:  Stop() is not intended for use if ExecOption is teRunThenFree.
    ///
    /// This method will return without waiting for the thread to actually stop
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the calling thread's context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    function Stop():Boolean;

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The public method, CanBeStarted() is a thread-safe method to determine
    /// if the thread is able to be resumed at the moment.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the calling thread's context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    function CanBeStarted():Boolean;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The public method, ThreadIsActive() is a thread-safe method to determine
    /// if the thread is actively running the assigned task.
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is referenced by outside threads OR by Self within its own context
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    function ThreadIsActive():Boolean;

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The protected method, WaitForHandle, is available for
    /// descendants as a way to Wait for a specific signal while respecting the
    /// Abortable Sleep signal on Stop requests, and also thread termination
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This method is referenced by Self within its own context and expected to
    /// be also be used by descendants
    /// event)
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    function WaitForHandle(const pHandle:THandle):Boolean;

    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The public event property, OnException, is executed when an error is
    /// trapped within the thread's Run loop
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the main thread's context via Synchronize.
    /// The property should only be set while the thread is inactive as it is
    /// referenced by Self within its own context in a non-threadsafe manner.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    property OnException:T5xExceptionEvent read fOnException write fOnException;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The public event property, OnRunCompletion, is executed as soon as the
    /// Run method exits
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the main thread's context via Synchronize.
    /// The property should only be set while the thread is inactive as it is
    /// referenced by Self within its own context in a non-threadsafe manner.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    property OnRunCompletion:T5xNotifyThreadEvent read fOnRunCompletion write fOnRunCompletion;
    {$IFDEF NODEF}{$REGION 'Documentation'}{$ENDIF}
    ///<summary>
    /// The public event property, OnReportProgress, is executed by descendant
    /// threads to report progress as needed back to the main thread
    ///</summary>
    ///<remarks>
    /// Context Note:
    /// This is executed within the main thread's context via Synchronize.
    /// The property should only be set while the thread is inactive as it is
    /// referenced by Self within its own context in a non-threadsafe manner.
    ///</remarks>
    {$IFDEF NODEF}{$ENDREGION}{$ENDIF}
    property OnReportProgress:TGetStrProc read fOnReportProgress write fOnReportProgress;
  end;


implementation

uses
  ActiveX,
  d5xWinApi;


constructor T5xThread.Create();
begin
  inherited Create(True); //We always create suspended, user must always call Start()

  fThreadState := tsSuspended_NotYetStarted;
  fStateChangeLock := T5xProcessResourceLock.Create();
  fAbortableSleepEvent := TEvent.Create(nil, True, False, '');
  fResumeSignal := TEvent.Create(nil, True, False, '');
end;


destructor T5xThread.Destroy();
begin
  if fThreadState = tsSuspended_NotYetStarted then
  begin
    //Workaround for issue of freeing a non-started thread that was created in suspended mode
    fAwakeToFreeEvent := TEvent.Create(nil, True, False, '');
    try
      Start();
      if GetCurrentThreadID = MainThreadID then
      begin
        WaitWithMessageLoop(fAwakeToFreeEvent.Handle, INFINITE);
      end
      else
      begin
        fAwakeToFreeEvent.WaitFor(INFINITE);
      end;
    finally
      FreeAndNil(fAwakeToFreeEvent);
    end;
  end;

  Terminate();
  fAbortableSleepEvent.SetEvent();
  fResumeSignal.SetEvent();
  inherited;

  fStateChangeLock.Free();
  fResumeSignal.Free();
  fAbortableSleepEvent.Free();
end;


procedure T5xThread.Execute();
begin
  try //except
  
    if Assigned(fAwakeToFreeEvent) then
    begin
      //We've awoken a thread created in Suspend mode simply to free it
      fAwakeToFreeEvent.SetEvent();
      Terminate();
      Exit;
    end;

    while not Terminated do
    begin
      if fRequireCoinitialize then
      begin
        CoInitialize(nil);
      end;
      try
        ThreadHasResumed();
        BeforeRun();
        try
          while ThreadIsActive() do // check for stop, externalstop, terminate
          begin
            Run(); //descendant's code
            DoOnRunCompletion();

            case ExecOption of
            teRepeatRun:
              begin
                //loop
              end;
            teRunThenSuspend:
              begin
                SuspendThread(tsSuspendPending_RunOnceComplete);
                Break;
              end;
            teRunThenFree:
              begin
                FreeOnTerminate := True;
                Terminate();
                Break;
              end;
            end;
          end; //while ThreadIsActive()
        finally
          AfterRun();
        end;
      finally
        if fRequireCoinitialize then
        begin
          //ensure this is called if thread is to be suspended
          CoUnInitialize();
        end;
      end;

      //Thread entering wait state
      WaitForResume;
      //Note: Only two reasons to wake up a suspended thread:
      //1: We are going to terminate it
      //2: we want it to restart doing work
    end; //while not Terminated
    
  except
    on E:Exception do
    begin
      fTrappedException := E;
      DoOnException();
    end;
  end;
end;


procedure T5xThread.WaitForResume();
begin
  fStateChangeLock.Lock();
  try
    if fThreadState = tsSuspendPending_StopRequestReceived then
    begin
      fThreadState := tsSuspended_ManuallyStopped;
    end
    else if fThreadState = tsSuspendPending_RunOnceComplete then
    begin
      fThreadState := tsSuspended_RunOnceCompleted;
    end;

    fResumeSignal.ResetEvent();
    fAbortableSleepEvent.ResetEvent();
  finally
    fStateChangeLock.Unlock();
  end;

  WaitForHandle(fResumeSignal.Handle);
end;


procedure T5xThread.ThreadHasResumed();
begin
  fAbortableSleepEvent.ResetEvent();
  fResumeSignal.ResetEvent();
end;


function T5xThread.ExternalRequestToStop:Boolean;
begin
  //Intended to be overriden - for descendant's use as needed
  Result := False;
end;


procedure T5xThread.BeforeRun();
begin
  //Intended to be overriden - for descendant's use as needed
end;


procedure T5xThread.AfterRun();
begin
  //Intended to be overriden - for descendant's use as needed
end;


function T5xThread.Start(const pExecOption:T5xThreadExecOption=teRepeatRun):Boolean;
begin
  if fStateChangeLock.TryLock() then
  begin
    try
      ExecOption := pExecOption;

      Result := CanBeStarted();
      if Result then
      begin
        if fThreadState = tsSuspended_NotYetStarted then
        begin
          fThreadState := tsActive;
          //We haven't started Exec loop at all yet
          //Since we start all threads in suspended state, we need one initial Resume()
         {$IFDEF RESUME_DEPRECATED}
           inherited Start();
         {$ELSE}
           Resume();
         {$ENDIF}
        end
        else
        begin
          fThreadState := tsActive;
          //we're waiting on Exec, wake up and continue processing
          fResumeSignal.SetEvent();
        end;
      end;
    finally
      fStateChangeLock.Unlock();
    end;
  end
  else //thread is not asleep
  begin
    Result := False;
  end;
end;


function T5xThread.Stop():Boolean;
begin
  if ExecOption <> teRunThenFree then
  begin
    fStateChangeLock.Lock();
    try
      if ThreadIsActive() then
      begin
        Result := True;
        SuspendThread(tsSuspendPending_StopRequestReceived);
      end
      else
      begin
        Result := False;
      end;
    finally
      fStateChangeLock.Unlock();
    end;
  end
  else
  begin
    //Never allowed to stop a FreeOnTerminate thread as we cannot properly
    //control thread termination from the outside in that scenario.
    Result := False;
  end;
end;


procedure T5xThread.SuspendThread(const pReason:T5xThreadState);
begin
  fStateChangeLock.Lock();
  try
    fThreadState := pReason; //will auto-suspend thread in Exec
    fAbortableSleepEvent.SetEvent();
  finally
    fStateChangeLock.Unlock();
  end;
end;


procedure T5xThread.Sync_CallOnRunCompletion();
begin
  if not Terminated then
  begin
    fOnRunCompletion(Self);
  end;
end;


procedure T5xThread.DoOnRunCompletion();
begin
  if Assigned(fOnRunCompletion) then
  begin
    CallSynchronize(Sync_CallOnRunCompletion);
  end;
end;


procedure T5xThread.Sync_CallOnException();
begin
  if not Terminated then
  begin
    fOnException(self, fTrappedException);
  end;
end;


procedure T5xThread.DoOnException();
begin
  if Assigned(fOnException) then
  begin
    CallSynchronize(Sync_CallOnException);
  end;
  fTrappedException := nil;
end;


function T5xThread.GetThreadState():T5xThreadState;
begin
  fStateChangeLock.Lock();
  try
    if Terminated then
    begin
      fThreadState := tsTerminated;
    end
    else if ExternalRequestToStop() then  //used by central Thread Manager
    begin
      fThreadState := tsSuspendPending_StopRequestReceived;
    end;
    Result := fThreadState;
  finally
    fStateChangeLock.Unlock();
  end;
end;


function T5xThread.GetExecOption():T5xThreadExecOption;
begin
  Result := T5xThreadExecOption(fExecOptionInt);
end;


procedure T5xThread.SetExecOption(const pVal:T5xThreadExecOption);
begin
  InterlockedExchange(fExecOptionInt, Ord(pVal));
end;


function T5xThread.CanBeStarted():Boolean;
begin
  if Assigned(fAwakeToFreeEvent) then
  begin
    //special case - wake up suspended thread simply to shutdown/free
    Result := True;
    Exit;
  end;


  if fStateChangeLock.TryLock() then
  begin
    try
      Result := (not Terminated) and
                (fThreadState in [tsSuspended_NotYetStarted,
                                  tsSuspended_ManuallyStopped,
                                  tsSuspended_RunOnceCompleted]);

    finally
      fStateChangeLock.UnLock();
    end;
  end
  else //thread isn't asleep
  begin
    Result := False;
  end;
end;


function T5xThread.ThreadIsActive():Boolean;
begin
  Result := (not Terminated) and (ThreadState = tsActive);
end;


procedure T5xThread.Sleep(const pSleepTimeMS:Integer);
begin
  if not Terminated then
  begin
    fAbortableSleepEvent.WaitFor(pSleepTimeMS);
  end;
end;


procedure T5xThread.CallSynchronize(const pMethod:TThreadMethod);
begin
  Synchronize(pMethod);
end;


procedure T5xThread.Sync_CallOnReportProgress();
begin
  if not Terminated then
  begin
    fOnReportProgress(fProgressTextToReport);
  end;
end;


procedure T5xThread.ReportProgress(const pAnyProgressText:String);
begin
  if Assigned(fOnReportProgress) then
  begin
    fProgressTextToReport := pAnyProgressText;
    CallSynchronize(Sync_CallOnReportProgress);
  end;
end;


function T5xThread.WaitForHandle(const pHandle:THandle):Boolean;
const
  WaitAllOption = False;
  IterateTimeOutMilliseconds = 200;
var
  vWaitForEventHandles:array[0..1] of THandle;
  vWaitForResponse:DWord;
begin
  Result := False;
  vWaitForEventHandles[0] := pHandle;   //initially for: fResumeSignal.Handle;
  vWaitForEventHandles[1] := fAbortableSleepEvent.Handle;

  while not Terminated do
  begin
    vWaitForResponse := WaitForMultipleObjects(2, @vWaitForEventHandles[0], WaitAllOption, IterateTimeOutMilliseconds);
    case vWaitForResponse of
    WAIT_TIMEOUT:
      begin
        Continue;
      end;
    WAIT_OBJECT_0:
      begin
        Result := True;  //initially for Resume, but also for descendants to use
        Break;
      end;
    WAIT_OBJECT_0 + 1:
      begin
        fAbortableSleepEvent.ResetEvent(); //likely a stop received while we are waiting for an external handle
        Break;
      end;
    WAIT_FAILED:
       begin
         {$IFDEF DELPHI6_UP}
         RaiseLastOSError;
         {$ELSE}
         RaiseLastWin32Error;
         {$ENDIF}
       end;
    end;
  end; //while not Terminated
end;


end.
