{$mode objfpc}
{$interfaces CORBA}
{$include targetos}

DEPRECATED

{$ifdef SDL}
{$undef TARGET_OS_MAC}
{$undef TARGET_OS_IPHONE}
{$endif}

{$if defined(TARGET_OS_MAC) or defined(TARGET_OS_IPHONE)}
{$modeswitch objectivec2}
{$endif}

unit USound;
interface
uses
	{$ifdef TARGET_OS_MAC}
	CocoaAll, AVFoundation,
	{$endif}
	{$ifdef TARGET_OS_IPHONE}
	iPhoneAll, AVFoundation,
	{$endif}
	UArray, UGeometry, UObject, SysUtils
	;

type
	TSound = class (TObject, IDelegation)
		public
			
			procedure Play; virtual; abstract;
			procedure Stop; virtual; abstract;
			procedure Reset; virtual; abstract;
			
			procedure SetVolume (newValue: TFloat); virtual; abstract;
			procedure SetNumberOfLoops (newValue: integer); virtual; abstract;
			procedure SetPan (newValue: TFloat); virtual; abstract;
			
			procedure SetMaximumVolume (newValue: TFloat); 
			procedure SetSource (newValue: TObject);
			function GetMaximumVolume: TFloat;
			function GetSource: TObject;

			procedure SetDelegate (newValue: TObject);
			function GetDelegate: TObject;
		protected
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;
		private
			_delegate: TObject;
			maximumVolume: TFloat;
			source: TObject;
			
			procedure Finished; virtual; abstract;
	end;

{$if defined(TARGET_OS_MAC) or defined(TARGET_OS_IPHONE)}	
type
	TAVFoundationSound = class (TSound)
		public
			constructor Create (path: string; _loops: boolean);
			
			procedure Play; override;
			procedure Stop; override;
			procedure Reset; override;
			
			procedure SetVolume (newValue: TFloat); override;
			procedure SetNumberOfLoops (newValue: integer); override;
			procedure SetPan (newValue: TFloat); override;
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;			
		private
			_player: AVAudioPlayer;
			data: NSData;
			fileType: NSString;
			loops: boolean;
			
			procedure Finished; override;
			function GetPlayer: AVAudioPlayer;
			property player: AVAudioPlayer read GetPlayer;
	end;
{$endif}

type
	ISoundDelegate = interface ['ISoundDelegate']
		procedure SoundDidPlay (sound: TSound);
		procedure SoundDidStop (sound: TSound);
	end;

implementation

{$if defined(TARGET_OS_MAC) or defined(TARGET_OS_IPHONE)}	

type
	TAVFoundationController = objcclass (NSObject, AVAudioPlayerDelegateProtocol)
		public
			procedure addSound (sound: TAVFoundationSound); message 'addSound:';
			procedure removeSound (sound: TAVFoundationSound); message 'removeSound:';
		private
			_sounds: TArray;
			function sounds: TArray; message 'sounds';
			procedure audioPlayerDidFinishPlaying_successfully (player: AVAudioPlayer; flag: boolean); message 'audioPlayerDidFinishPlaying:successfully:';
	end;

var
	AudioController: TAVFoundationController = nil;

procedure TAVFoundationController.addSound (sound: TAVFoundationSound);
begin
	sounds.AddValue(sound);
end;

procedure TAVFoundationController.removeSound (sound: TAVFoundationSound);
begin
	sounds.RemoveValue(sound);
end;

function TAVFoundationController.sounds: TArray;
begin
	if _sounds = nil then	
		_sounds := TArray.Create;
	result := _sounds;
end;

procedure TAVFoundationController.audioPlayerDidFinishPlaying_successfully (player: AVAudioPlayer; flag: boolean);
var
	sound: TAVFoundationSound;
begin
	for pointer(sound) in sounds do
		if sound.player = player then
			begin
				sound.Retain;
				removeSound(sound);
				sound.Finished;
				sound.Release;
				break;
			end;
end;

function TAVFoundationSound.GetPlayer: AVAudioPlayer;
var
	error: NSError;
begin
	if _player = nil then
		begin
			_player := AVAudioPlayer(AVAudioPlayer.alloc).initWithData_fileTypeHint_error(data, fileType, @error);	
			if _player <> nil then
				begin
					_player.setDelegate(AudioController);
					AudioController.addSound(self);
					if loops then
						_player.setNumberOfLoops(-1);
				end
			else
				raise Exception.Create('AVAudioPlayer failed to load: '+error.localizedDescription.UTF8String);
		end;
	result := _player;
end;

constructor TAVFoundationSound.Create (path: string; _loops: boolean);
var
	error: NSError;
begin
	{data := NSData.alloc.initWithContentsOfFile(NSSTR(path));
	if data = nil then	
		raise Exception.Create('The sound file "'+path+'" failed to load from disk.');
	
	if AudioController = nil then
		AudioController := TAVFoundationController.alloc.init;
	
	fileType := NSWorkspace.sharedWorkspace.typeOfFile_error(NSSTR(path), nil).retain;
	loops := _loops;
	//player := AVAudioPlayer(AVAudioPlayer.alloc).initWithContentsOfURL_error(NSURL.fileURLWithPath(NSSTR(path)), @error);
	Initialize;}
	writeln('DEAD');
	halt;
end;

procedure TAVFoundationSound.SetVolume (newValue: TFloat);
begin
	player.setVolume(newValue);
end;

procedure TAVFoundationSound.SetNumberOfLoops (newValue: integer);
begin
	player.setNumberOfLoops(newValue);
end;

procedure TAVFoundationSound.SetPan (newValue: TFloat);
begin
	player.setPan(newValue);
end;

procedure TAVFoundationSound.Play;
var
	delegate: ISoundDelegate;
begin
	if not player.play then
		writeln('sound failed to play');
	if Supports(GetDelegate, ISoundDelegate, delegate) then
		delegate.SoundDidPlay(self);
end;

procedure TAVFoundationSound.Stop;
var
	delegate: ISoundDelegate;
begin
	if _player <> nil then
		begin
			Retain;
			player.stop;
			AudioController.removeSound(self);
			if Supports(GetDelegate, ISoundDelegate, delegate) then
				delegate.SoundDidStop(self);
			Release;
		end
	else
		raise Exception.Create('The sound can''t be stopped because it never started.');
end;

procedure TAVFoundationSound.Finished;
var
	delegate: ISoundDelegate;
begin
	if Supports(GetDelegate, ISoundDelegate, delegate) then
		delegate.SoundDidStop(self);
end;

procedure TAVFoundationSound.Reset;
begin
	player.setCurrentTime(0.0);
end;

procedure TAVFoundationSound.CopyInstanceVariables (clone: TObject);
var
	sound: TAVFoundationSound;
begin
	inherited CopyInstanceVariables(clone);
	
	sound := TAVFoundationSound(clone);
	data := sound.data.retain;
	fileType := sound.fileType.retain;
	loops := sound.loops;
end;

procedure TAVFoundationSound.Deallocate;
begin
	//writeln('dealloc ', getdebugstring);
	data.release;
	fileType.release;
	_player.release;
	
	inherited Deallocate;
end;

procedure TAVFoundationSound.Initialize;
begin
	inherited Initialize;
	
	RegisterMethod('Play', @TAVFoundationSound.Play);
end;
{$endif}

procedure TSound.CopyInstanceVariables (clone: TObject);
var
	sound: TSound;
begin
	inherited CopyInstanceVariables(clone);
	
	sound := TSound(clone);
	if sound.GetDelegate <> nil then
		_delegate := sound.GetDelegate.Retain;
end;

procedure TSound.SetSource (newValue: TObject);
begin
	source := newValue;
end;

function TSound.GetSource: TObject;
begin
	result := source;
end;

procedure TSound.SetMaximumVolume (newValue: TFloat);
begin
	maximumVolume := newValue;
end;

function TSound.GetMaximumVolume: TFloat;
begin
	result := maximumVolume;
end;

procedure TSound.SetDelegate (newValue: TObject);
begin
	RetainObject(TObject(_delegate), newValue);
end;

function TSound.GetDelegate: TObject;
begin
	result := _delegate;
end;

procedure TSound.Deallocate;
begin
	ReleaseObject(_delegate);
	inherited Deallocate;
end;

end.