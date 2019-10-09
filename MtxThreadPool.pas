// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2011, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################
// ###################################################################
// #### certain MACOS contributions and testing William Cantrall
// ###################################################################

unit MtxThreadPool;

// #####################################################
// #### Thread pool for async matrix operations stub.
// #### The real implementation is OS dependent!
// #####################################################

interface

uses MatrixConst;

{$IFDEF FPC} {$IFDEF DARWIN}
  {$DEFINE MACOS}   // delphi defines macos, fpc darwin
{$ENDIF}{$ENDIF}

type
  TMtxProc = procedure(obj : TObject);
  TMtxRecProc = procedure(rec : Pointer);

type
  IMtxAsyncCall = interface
   ['{B5263EB3-FFDE-4D66-B556-31D5E0D05BAC}']
    procedure ExecuteAsync;
    procedure Sync;
  end;
  IMtxAsyncCallGroup = interface
   ['{11438431-7A6A-4FB9-B67A-58CE23E324DB}']
   procedure AddTask(proc : TMtxProc; obj : TObject);
   procedure AddTaskRec(proc : TMtxRecProc; rec : Pointer);
   procedure SyncAll;
  end;

// ################################################
// #### interfaces that need to be implemented for external
// thread pools
type
  IMtxThreadPool = interface
    ['{9BF6425A-A6DD-466E-B642-7BE05282CADD}']
    procedure InitPool( maxNumThreads : integer );
    function CreateTaskGroup : IMtxAsyncCallGroup;
  end;

type
  TThreadPoolProviderFunc = function : IMtxThreadPool;

// these functions are called in the matrix library
procedure SetThreadPoolProvider( func : TThreadPoolProviderFunc );

procedure InitMtxThreadPool;
procedure FinalizeMtxThreadPool;
function MtxInitTaskGroup : IMtxAsyncCallGroup;

const cMaxNumCores = 64;                          // limit the maximum usabel cores

var numCPUCores : TASMNativeInt = 0;
    numRealCores : TASMNativeInt = 0;             // cores without hyperthreading
    numCoresForSimpleFuncs : TASMNativeInt = 0;   // for median and scaling operations

implementation

{$IFDEF MSWINDOWS }
uses {$IFDEF USE_OS_THREADPOOL}SimpleWinThreadPool{$ELSE} WinThreadPool{$ENDIF};
{$ENDIF}
{$IFDEF LINUX}
uses linuxthrpool;
{$ENDIF}
// delphi define
{$IFDEF MACOS}
uses MacOsThreadPool;
{$ENDIF}


var threadPoolProviderFunc : TThreadPoolProviderFunc;
    thrPool : IMtxThreadPool = nil;

procedure SetThreadPoolProvider( func : TThreadPoolProviderFunc );
begin
     threadPoolProviderFunc := {$IFDEF FPC}@{$ENDIF}func;
end;

procedure InitMtxThreadPool;
begin
     if thrpool = nil then
     begin
          thrPool := threadPoolProviderFunc();
          thrPool.InitPool(numCPUCores);
     end;
end;

procedure FinalizeMtxThreadPool;
begin
     thrPool := nil;
end;

function MtxInitTaskGroup : IMtxAsyncCallGroup;
begin
     assert(Assigned(thrPool), 'Error call InitMtxThreadPool first');
     Result := thrPool.CreateTaskGroup;
end;

end.
