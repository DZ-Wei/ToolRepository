//
//  ViewController.m
//  FD_ToolsDemo
//
//  Created by ZunHao on 15/9/7.
//  Copyright (c) 2015年 WFD. All rights reserved.
//

#import "ViewController.h"
#import "FD_DrawView.h"


/** 邮件发送*/
#import <MessageUI/MFMailComposeViewController.h>

/** JS框架*/
#import <JavaScriptCore/JavaScriptCore.h>

/** 蓝牙通讯*/
#import <CoreBluetooth/CoreBluetooth.h>
/** 服务UUID*/
#define UUIDSTR_ISSC_PROPRIETARY_SERVICE (@"1234567890")
/** 读特征UUID*/
#define UUIDSTR_ISSC_TRANS_TX (@"999999")
/** 写特征UUID*/
#define UUIDSTR_ISSC_TRANS_RX (@"888888")

/** 录音相关开发*/
#import <AVFoundation/AVFoundation.h>
/** 文件路劲文件夹*/
#define FD_DocumentsFile ([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject])
/** Mp3转码*/
#import "lame.h"

/** runloop相关*/
#define LOCAL_MACH_PORT_NAME "com.zunhao"


/** JS通讯声明回调方法*/
@protocol webViewJSExport <JSExport>
JSExportAs(callPay, -(void)callPay:(NSString *)charge success:(NSString *)success cancel:(NSString *)cancel);
@end

@interface ViewController ()<MFMailComposeViewControllerDelegate,UIWebViewDelegate,webViewJSExport,CBCentralManagerDelegate,CBPeripheralDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate>
{
    /** 录音相关*/
    UIButton *_recorderBtn;
    UIButton *_audioPlayBtn;
    BOOL recording;
    NSURL *tmpFile;
    NSInteger _count;
    NSInteger _modelId;
    NSString *_path;
    
    /** runloop 相关*/
    CFMessagePortRef msg_port_ref;

}

/** Js通信*/
@property(nonatomic,strong)JSContext *context;
/** 蓝牙中心设备管理*/
@property(nonatomic,strong)CBCentralManager *centerManager;

/** TextView*/
@property(nonatomic,strong)UITextView *textView;

/** 录音对象*/
@property(nonatomic,strong)AVAudioRecorder *recorder;
/** 播放对象*/
@property(nonatomic,strong)AVAudioPlayer *audioPlay;



@end

@implementation ViewController

#pragma mark - =====View Control生命周期=====
-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self CreateStartListenning];
//    [self createRunLoopExamplesView];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}


#pragma mark - =====GCD使用=====
/** GCD常规使用*/
-(void)createGCDExamplesView
{
    /** runloop 定时器*/
    dispatch_source_t soure_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_global_queue(0, 0));
}



#pragma mark - =====RunLoop的基本使用=====
/** runloop基础使用*/
-(void)createRunLoopExamplesView
{
    [NSThread detachNewThreadSelector:@selector(runThreadMethod) toTarget:self withObject:nil];
    
}
/** 启动线程回调*/
-(void)runThreadMethod
{
    @autoreleasepool
    {
        NSRunLoop *current_runLoop = [NSRunLoop currentRunLoop];
        /** runloop 运行环境*/
        CFRunLoopObserverContext runloop_context = {0,(__bridge_retained void *)self,NULL,NULL,NULL};
        
        /** runloop observer*/
        CFRunLoopObserverRef observer_ref = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runloopObserverCallBack, &runloop_context);

        if (observer_ref)
        {
            CFRunLoopRef cfrunloop_ref = [current_runLoop getCFRunLoop];
            /** 添加runloop observer*/
            CFRunLoopAddObserver(cfrunloop_ref, observer_ref, kCFRunLoopDefaultMode);
            
        }
        /** timer soure */
       [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(timerProcess) userInfo:nil repeats:YES];
        
        NSInteger loop_count = 2;
        do
        {
            /** 唤醒runloop*/
            [current_runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5.f]];
            loop_count--;
            NSLog(@"loop_count=====%li",loop_count);
            
        } while (loop_count);
        
    }
}

- (void)timerProcess
{
    for (int i=0; i<5; i++)
    {
        NSLog(@"In timerProcess count = %d.", i);
        sleep(1);
    }
    
}

/** runloop observer call back*/
void runloopObserverCallBack(CFRunLoopObserverRef observer,CFRunLoopActivity activity,void *info)
{
    switch (activity)
    {
        case kCFRunLoopEntry:
        {
            NSLog(@"run loop entry");
            break;
        }
            
        case kCFRunLoopBeforeTimers:
        {
            NSLog(@"run loop before timers");
            break;
        }
        case kCFRunLoopBeforeSources:
        {
            NSLog(@"run loop before sources");
            break;
        }
        case kCFRunLoopBeforeWaiting:
        {
            NSLog(@"run loop before waiting");
            break;
        }
        case kCFRunLoopExit:
        {
            NSLog(@"run loop exit");
            break;
        }
        case kCFRunLoopAfterWaiting:
        {
            NSLog(@"run loop after waiting");
            
            break;
        }
        case kCFRunLoopAllActivities:
        {
            NSLog(@"run loop All Activities");
            break;
        }
            
    }
    
}

/** 创建基于端口的输入源---(消息发送者 ios7.0后此通讯方式已失效)*/
-(NSString *)createSendMsgWithRunLoopPortSoure:(id)msgInfo AdMsgId:(SInt32)msgid
{
    CFMessagePortRef send_port_ref = CFMessagePortCreateRemote(kCFAllocatorDefault, CFSTR(LOCAL_MACH_PORT_NAME));
    if (NULL == send_port_ref)
    {
        NSLog(@"PortCreateRemote failed");
        return nil;
    }
    /** 构建发送数据*/
    NSString *msg = [NSString stringWithFormat:@"%@",msgInfo];
    const char *message = [msg UTF8String];
    CFDataRef data,recvData = nil;
    data = CFDataCreate(NULL, (UInt8 *)message, strlen(message));
    
    /** 执行发送操作*/
    CFMessagePortSendRequest(send_port_ref, msgid, data, 0, 100, kCFRunLoopDefaultMode, &recvData);
    /** 解析返回的数据*/
    const UInt8  * recvedMsg = CFDataGetBytePtr(recvData);
    if (NULL == recvData || NULL == recvedMsg)
    {
        CFRelease(data);
        CFMessagePortInvalidate(send_port_ref);
        CFRelease(send_port_ref);
        return nil;
    }
    NSString *strMsg = [NSString stringWithCString:(char *)recvedMsg encoding:NSUTF8StringEncoding];
    
    CFRelease(data);
    CFMessagePortInvalidate(send_port_ref);
    CFRelease(send_port_ref);
    CFRelease(recvData);
    return strMsg;
    
}


#pragma mark - ======RunLoop基于端口的输入源=====
/** 创建基于端口的输入源---(注册消息接收者)*/
-(void)CreateStartListenning
{
    if (msg_port_ref && CFMessagePortIsValid(msg_port_ref))
    {
        CFMessagePortInvalidate(msg_port_ref);
    }
    msg_port_ref = CFMessagePortCreateLocal(kCFAllocatorDefault, CFSTR(LOCAL_MACH_PORT_NAME), NULL, NULL, NULL);
    /** add runloop */
    CFRunLoopSourceRef msg_port_soure = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, msg_port_ref, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), msg_port_soure, kCFRunLoopCommonModes);
    
}

/** 取消消息监听*/
-(void)endListenning
{
    CFMessagePortInvalidate(msg_port_ref);
    CFRelease(msg_port_ref);
}

/** 消息接收者回调*/
CFDataRef onRecvMessageCallBack(CFMessagePortRef local,SInt32 msgid,CFDataRef cfData,void* info)
{
    NSString *stringData = nil;
    if (cfData)
    {
        const UInt8 *recvedMsg = CFDataGetBytePtr(cfData);
        stringData = [NSString stringWithCString:(char *)recvedMsg encoding:NSUTF8StringEncoding];
        
        /** 实现数据解析*/
    }
    /** 生成返回数据给消息发送者*/
    NSString *returnString = @"send msg succeed";
    const char * cStr = [returnString UTF8String];
    NSUInteger cStrLeng = [returnString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    return CFDataCreate(NULL, (UInt8 *)cStr, cStrLeng);
}

#pragma mark - =====RunLoop自定义输入源=====
/** 创建自定义输入源*/
void createCustomSounre()
{
    CFRunLoopSourceContext custom_context = {0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};
    CFRunLoopSourceRef soure_ref = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &custom_context);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), soure_ref, kCFRunLoopDefaultMode);
    BOOL run_stare = YES;
    while (run_stare)
    {
        @autoreleasepool
        {
            CFRunLoopRun();
        }
    }
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), soure_ref, kCFRunLoopDefaultMode);
    CFRelease(soure_ref);
    
}






#pragma mark - =====绘制图形=====
/** 绘制View*/
-(void)createDrawView
{
    UIView *drawView = [[UIView alloc]initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height -64)];
    [self.view addSubview:drawView];
    
    /** 虚线圆*/
    CAShapeLayer *dotteLine =  [CAShapeLayer layer];
    CGMutablePathRef dottePath =  CGPathCreateMutable();
    dotteLine.lineWidth = 2.0f ;
    dotteLine.strokeColor = [UIColor orangeColor].CGColor;
    dotteLine.fillColor = [UIColor clearColor].CGColor;
    CGPathAddEllipseInRect(dottePath, nil, CGRectMake(50.0f,  50.0f, 200.0f, 200.0f));
    dotteLine.path = dottePath;
    NSArray *arr = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:10],[NSNumber numberWithInt:100], nil];
    dotteLine.lineDashPhase = 1.0;
    dotteLine.lineDashPattern = arr;
    CGPathRelease(dottePath);
    
    [drawView.layer addSublayer:dotteLine];
}



#pragma mark - =====图片人脸识别=====
/** 识别准确率较低---待更换*/
-(void)createFaceCheckView
{
    UIImage *aImage = [UIImage imageNamed:@"face.jpg"];
    UIImageView *faceImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, aImage.size.width, aImage.size.height)];
    faceImageView.image = aImage;
    faceImageView.center = self.view.center;
    [self.view addSubview:faceImageView];
    
    CIImage* image = [CIImage imageWithCGImage:aImage.CGImage];
    NSDictionary  *opts = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh
                                                      forKey:CIDetectorAccuracy];
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:opts];
    NSArray* features = [detector featuresInImage:image];
    
    UIView *pointViw = [[UIView alloc]initWithFrame:CGRectMake(276, 218, 2, 2)];
    pointViw.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:pointViw];
    
    
    for (CIFaceFeature *f in features)
    {
        CGRect aRect = f.bounds;
        NSLog(@"%f, %f, %f, %f", aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height);
        
        //眼睛和嘴的位置
        if(f.hasLeftEyePosition) NSLog(@"Left eye %g %g\n", f.leftEyePosition.x, f.leftEyePosition.y);
        if(f.hasRightEyePosition) NSLog(@"Right eye %g %g\n", f.rightEyePosition.x, f.rightEyePosition.y);
        if(f.hasMouthPosition) NSLog(@"Mouth %g %g\n", f.mouthPosition.x, f.mouthPosition.y);
    }
    
    
}



#pragma mark - =====TextView相关=====
-(void)createTextViewTest
{
    self.textView = [[UITextView alloc]initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height- 64)];
    self.textView.font = [UIFont systemFontOfSize:14.f];
    self.textView.layer.borderWidth=1;
    self.textView.layer.borderColor=[UIColor clearColor].CGColor;
    self.textView.returnKeyType = UIReturnKeyDone;
    self.textView.attributedText = [self sampleAttributedString];
    [self.view addSubview:self.textView];
    
    UITapGestureRecognizer *hidKeyborad = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hidetKeyBoradAtView:)];
    [self.view addGestureRecognizer:hidKeyborad];
    
}

-(void)hidetKeyBoradAtView:(UIGestureRecognizer *)gestur
{
    [self.view endEditing:YES];
}

-(void)imageClicked:(UIGestureRecognizer *)gesture
{
    NSLog(@"点击图片");
}

- (NSAttributedString*)sampleAttributedString
{
    NSMutableAttributedString *attributedText = [NSMutableAttributedString new];
    
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"信用卡额度突然降了，是咋回事？网友小张年前办了一张信用卡，初始额度为2万元，小张嫌额度不够高，于是想了各种招式频繁刷卡,于是想了各种招式频繁，于是想了各种招式频繁.信用卡额度突然降了，是咋回事？网友小张年前办了一张信用卡，初始额度为2万元，小张嫌额度不够高，于是想了各种招式频繁刷卡,于是想了各种招式频繁，于是想了各种招式频繁\n\n"]];
    
    NSTextAttachment *textAttachment = [NSTextAttachment new];
    UIImage *pictImage = [UIImage imageNamed:@"Icon.png"];
    textAttachment.bounds =  CGRectMake(0, 0, self.textView.bounds.size.width - 10, 200);
    textAttachment.image = pictImage;
    

    
    
    [attributedText appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
    
    [attributedText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:(14)] range:NSMakeRange(0, attributedText.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName
                           value:[UIColor colorWithRed:(83)/255.0 green:(83)/255.0 blue:(83)/255.0 alpha:1.0]
                           range:NSMakeRange(0, attributedText.length)];
    
    NSData *tesData = [NSKeyedArchiver archivedDataWithRootObject:attributedText];
    [[NSUserDefaults standardUserDefaults]setObject:tesData forKey:@"TestData"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    return attributedText;
}


#pragma mark - =====录音播放相关=====
/** 录音相关功能*/
-(void)createSoundRecording
{
    _recorderBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _recorderBtn.frame = CGRectMake(100, 100, 100, 100);
    [_recorderBtn setTitle:@"录音" forState:UIControlStateNormal];
    [_recorderBtn setBackgroundColor:[UIColor orangeColor]];
    _recorderBtn.layer.masksToBounds = YES;
    _recorderBtn.layer.cornerRadius = _recorderBtn.bounds.size.width *0.5;
    [_recorderBtn addTarget:self action:@selector(recorderButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_recorderBtn];
    
    _audioPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _audioPlayBtn.frame = CGRectMake(100, 250, 100, 100);
    [_audioPlayBtn setTitle:@"播放" forState:UIControlStateNormal];
    [_audioPlayBtn setBackgroundColor:[UIColor orangeColor]];
    _audioPlayBtn.layer.masksToBounds = YES;
    _audioPlayBtn.layer.cornerRadius = _audioPlayBtn.bounds.size.width *0.5;
    [_audioPlayBtn addTarget:self action:@selector(audioPlayButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_audioPlayBtn];
    
    
    UIButton *eoderBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    eoderBtn.frame = CGRectMake(100, 400, 100, 100);
    [eoderBtn setTitle:@"转码" forState:UIControlStateNormal];
    [eoderBtn setBackgroundColor:[UIColor orangeColor]];
    eoderBtn.layer.masksToBounds = YES;
    eoderBtn.layer.cornerRadius = _audioPlayBtn.bounds.size.width *0.5;
    [eoderBtn addTarget:self action:@selector(eodeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:eoderBtn];

    
    
    _modelId = 10;
    [_audioPlayBtn setEnabled:NO];
    _audioPlayBtn.titleLabel.alpha = 0.5f;
    tmpFile =  [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%ld",[self createFileForModelId:[NSString stringWithFormat:@"%ld",_modelId]],_count]];
    _path = [NSString stringWithFormat:@"%@/%ld",[self createFileForModelId:[NSString stringWithFormat:@"%ld",_modelId]],_count];
    
    /** 设置后台播放*/
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    if (!session)
    {
        NSLog(@"Error creating sessing:%@", [sessionError description]);
    }else
    {
        [session setActive:YES error:nil];
    }
    /** 是否打开麦克风*/
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted)
    {
        if (granted)
        {
            NSLog(@"麦克风已经打开");
        }else
        {
            NSLog(@"未打开麦克风");
        }
    }];
}

/** 创建模型id对应文件夹*/
-(NSString *)createFileForModelId:(NSString *)modelid
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [NSString stringWithFormat:@"%@/%@",FD_DocumentsFile,modelid];
    if (![fileManager fileExistsAtPath:path])
    {
        NSError *error;
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error)
        {
            NSLog(@"create file error:%@",[error localizedDescription]);
            return nil;
        }
    }
    return path;
}
/** 获取指定路径下所有文件*/
-(NSArray *)getPathForFile:(NSString *)path
{
    if (!path.length) return nil;
    NSError *error;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSArray *tempArr = [[NSArray alloc]initWithArray:[fileManager contentsOfDirectoryAtPath:path error:&error]];
    if (error)
    {
        NSLog(@"getfile is error:%@",[error localizedDescription]);
        return nil;
    }
    return tempArr;
}

/** 录音参数设置*/
-(NSDictionary *)recorderSetting
{
    NSMutableDictionary * recordSetting = [ NSMutableDictionary dictionary ];
    [recordSetting setValue :[ NSNumber numberWithInt : kAudioFormatLinearPCM ] forKey : AVFormatIDKey ]; //
    [recordSetting setValue :[ NSNumber numberWithFloat : 8000.0 ] forKey : AVSampleRateKey ];//采样率
    [recordSetting setValue :[ NSNumber numberWithInt : 2 ] forKey : AVNumberOfChannelsKey ];//声音通道， 这里必须为双通道
    [recordSetting setValue :[ NSNumber numberWithInt : AVAudioQualityLow ] forKey : AVEncoderAudioQualityKey ];//音频质量
    return recordSetting;
}


/** 录音Action*/
-(void)recorderButtonClicked:(UIButton *)sender
{
    if (!recording)
    {
        recording = YES;
        [_recorderBtn setTitle:@"停止" forState:UIControlStateNormal];
        [_audioPlayBtn setEnabled:NO];
        _audioPlayBtn.titleLabel.alpha = 0.5f;

        
        self.recorder = [[AVAudioRecorder alloc] initWithURL:tmpFile settings:[self recorderSetting] error:nil];
        self.recorder.delegate = self;
        //准备记录录音
        [_recorder prepareToRecord];
        //启动或者恢复记录的录音文件
        [_recorder record];
        self.audioPlay = nil;
        
    }
    else
    {
        recording = NO;
        [_recorderBtn setTitle:@"录音" forState:UIControlStateNormal];
        [_audioPlayBtn setEnabled:YES];
        _audioPlayBtn.titleLabel.alpha = 1.f;
        [self.recorder stop];
        self.recorder = nil;
        
        NSError *playError;
        self.audioPlay = [[AVAudioPlayer alloc] initWithContentsOfURL:tmpFile error:&playError];
        
        if (playError)
        {
             NSLog(@"Error crenting player: %@", [playError description]);
        }
        self.audioPlay.delegate = self;
    }

}

/** 播放Action*/
-(void)audioPlayButtonClicked:(UIButton *)sender
{
     if ([self.audioPlay isPlaying])
     {
         [self.audioPlay pause];
         [_audioPlayBtn setTitle:@"播放" forState:0];
     }else
     {
         /** 预播放获取时间*/
         [self.audioPlay prepareToPlay];
         NSLog(@"语音时间====%f",self.audioPlay.duration);
         NSLog(@"path====%@",_path);
         NSLog(@"语音文件大小====%ld",[self getFileSize:_path]);
         [self.audioPlay play];
         [_audioPlayBtn setTitle:@"暂停" forState:0];

     }
}

/** 转码Action*/
-(void)eodeButtonClicked:(UIButton *)sender
{
    NSString *cafFilePath = _path;    //caf文件路径
    NSString *mp3FilePath = @"/Users/WFD/Mp3File/temp.mp3";//存储mp3文件的路径
    NSFileManager * fileManager=[ NSFileManager defaultManager ];
    if ([fileManager removeItemAtPath :mp3FilePath error : nil ])
    {
        NSLog (@"删除");
    }

    @try
    {
        int read, write;
        FILE *pcm = fopen ([cafFilePath cStringUsingEncoding : 1 ], "rb" );  //source 被 转换的音频文件位置
        if (pcm == NULL )
        {
            NSLog ( @"file not found" );
        }
        else
        {
            fseek (pcm, 4 * 1024 , SEEK_CUR );                                   //skip file header
            FILE *mp3 = fopen ([mp3FilePath cStringUsingEncoding : 1 ], "wb" );  //output 输出生成的 Mp3 文件位置
            
            const int PCM_SIZE = 8192 ;
            const int MP3_SIZE = 8192 ;
            short int pcm_buffer[PCM_SIZE* 2 ];
            unsigned char mp3_buffer[MP3_SIZE];
            lame_t lame = lame_init ();
            lame_set_num_channels (lame, 1 ); // 设置 1 为单通道，默认为 2 双通道
            lame_set_in_samplerate (lame, 8000.0 ); //11025.0
            //lame_set_VBR(lame, vbr_default);
            lame_set_brate (lame, 8 );
            lame_set_mode (lame, 3 );
            lame_set_quality (lame, 2 ); /* 2=high 5 = medium 7=low 音 质 */
            lame_init_params (lame);

            do
            {
                read = fread (pcm_buffer, 2 * sizeof (short int ), PCM_SIZE, pcm);
                if (read == 0 )
                {
                    write = lame_encode_flush (lame, mp3_buffer, MP3_SIZE);
                }
                else
                {
                    write = lame_encode_buffer_interleaved (lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                }
                fwrite (mp3_buffer, write, 1 , mp3);

            }
            while (read != 0 );
            lame_close (lame);
            fclose (mp3);
            fclose (pcm);
        }
        
    }
    
    @catch (NSException *exception)
    {
        NSLog ( @"%@" ,[exception description ]);
    }
    
    @finally
    {
        NSLog (@"执行完成");
    }
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    _count++;
    tmpFile =  [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%ld",[self createFileForModelId:[NSString stringWithFormat:@"%ld",_modelId]],_count]];
    
    NSLog(@"录音成功");
}
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"录音失败");
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [_audioPlayBtn setTitle:@"播放" forState:0];
    NSLog(@"完成播放");
}
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"播放失败");
}

- (NSInteger)getFileSize:(NSString*) path
{

    
    NSFileManager * filemanager = [[NSFileManager alloc]init];
    if([filemanager fileExistsAtPath:path])
    {
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ((theFileSize = [attributes objectForKey:NSFileSize]))
            return  [theFileSize intValue];
        else
            return -1;
    }
    else{
        return -1;
    }
}


#pragma mark - =====蓝牙通讯开发相关=====
/** 创建蓝牙通讯*/
-(void)createBlueMessage
{
    UIButton *emailBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    emailBtn.frame = CGRectMake(0, 0, 120, 120);
    emailBtn.center = self.view.center;
    [emailBtn setTitle:@"CoreBlue" forState:UIControlStateNormal];
    [emailBtn setBackgroundColor:[UIColor orangeColor]];
    [emailBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    emailBtn.layer.masksToBounds = YES;
    emailBtn.layer.cornerRadius = emailBtn.bounds.size.width *0.5;
    [emailBtn addTarget:self action:@selector(openBlueClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:emailBtn];
    
  
}
/** Open BlueClicked*/
-(void)openBlueClicked:(UIButton *)sender
{
    if (self.centerManager) return;
    self.centerManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
}


/** 中心设备管理回调*/
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSString * state = nil;
    switch ([central state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
        {
            state = @"succeeds";
            /** 扫描外设*/
            [self.centerManager scanForPeripheralsWithServices:nil options:nil];
            break;
        }
        case CBCentralManagerStateUnknown:
        default:
            ;
    }
    
    NSLog(@"Central manager state: %@", state);
}


/** 发现外设设备回调*/
/** 
    peripheral：外设设备
    advertisementData：设备广告数据
    RSSI：信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
#if 0
    NSString *str = [NSString stringWithFormat:@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.identifier, advertisementData];
    NSLog(@"%@",str);
#endif
    NSLog(@"UUIDString====%@",peripheral.identifier.UUIDString);
    
#if 0
    /** 开启链接外设*/
    [self.centerManager connectPeripheral:peripheral options:nil];
    [self.centerManager stopScan];
#endif

    
}

/** 已经链接外设回调*/
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    /** 发现外设中的服务*/
    NSLog(@"链接外设成功");
    [peripheral discoverServices:nil];
}
/** 链接外设失败回调*/
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"链接外设失败");
}
/** 断开外设链接回调*/
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"断开外设链接");
}

/** ============================================================================
    ============================================================================
 */

/** 完成_发现外设服务完成回调*/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    for (CBService *service in peripheral.services)
    {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_PROPRIETARY_SERVICE]])
        {
            NSLog(@"Service found with UUID: %@", service.UUID);
            /** 发现服务里的特征*/
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}
/** 完成_发现服务中的特征回调*/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]])
        {
            NSLog(@"匹配读特征");
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_RX]])
        {
            NSLog(@"匹配写特征");

        }
    }
    
}





#pragma mark - =====CLayer核心动画相关=====
/** Layer创建与初始化*/
-(void)createCustomLayer
{
    CALayer *layer = [[CALayer alloc]init];
    layer.backgroundColor = [UIColor orangeColor].CGColor;
    layer.bounds = CGRectMake(0, 0, 200, 150);
    layer.anchorPoint = CGPointZero;
    layer.position = CGPointMake(100, 100);
    layer.cornerRadius = 20;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeMake(10, 20);
    layer.shadowOpacity = 0.6;
    layer.delegate = self;
    [layer setNeedsDisplay];
    [self.view.layer addSublayer:layer];
}
/** Layer绘制回调*/
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    CGContextAddEllipseInRect(ctx, CGRectMake(0, 50, 100, 100));
    CGContextSetRGBFillColor(ctx, 0, 0, 1, 1);
    CGContextFillPath(ctx);
}

#pragma mark - =====JavaScriptcore与OC端通讯相关=====
/** 创建与初始化*/
-(void)createJSAndOCMessage
{
    UIWebView *testWebView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64)];
    testWebView.delegate  = self;
    [self.view addSubview:testWebView];
    [testWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com/"]]];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    /** 
        JS端调用：TXBB_IOS_SDK.callPay(charge, this.success, this.cancel);
     */
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.context[@"TXBB_IOS_SDK"] = self;
    
    /**OC端调用JS端方法
    JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    NSString *alertJs = @"alert('Hello Word')";
    [context evaluateScript:alertJs];
     */
}
/** JS端回调OC端方法*/
- (void)callPay:(NSString *)charge success:(NSString *)success cancel:(NSString *)cancel
{
    NSLog(@"JS端开启调用");
}


#pragma mark - =====邮件发送相关=====
/** 创建与初始化*/
-(void)createSendMail
{
    UIButton *emailBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    emailBtn.frame = CGRectMake(0, 0, 100, 100);
    emailBtn.center = self.view.center;
    [emailBtn setTitle:@"Send" forState:UIControlStateNormal];
    [emailBtn setBackgroundColor:[UIColor orangeColor]];
    [emailBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    emailBtn.layer.masksToBounds = YES;
    emailBtn.layer.cornerRadius = emailBtn.bounds.size.width *0.5;
    [emailBtn addTarget:self action:@selector(sendMailInApp:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:emailBtn];
}

/** 检测是否支持*/
- (void)sendMailInApp:(UIButton *)sender
{
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (!mailClass)
    {
        [self alertWithMessage:@"当前系统版本不支持应用内发送邮件功能，您可以使用mailto方法代替"];
        return;
    }
    if (![mailClass canSendMail])
    {
        [self alertWithMessage:@"用户没有设置邮件账户"];
        return;
    }
    [self displayMailPicker];
}
/** 准备发送*/
-(void)displayMailPicker
{
    MFMailComposeViewController *mailPicker = [[MFMailComposeViewController alloc] init];
    mailPicker.mailComposeDelegate = self;
    [mailPicker setSubject:@"email主题"];
    /** 设置收件人*/
    NSArray *toRecipients = [NSArray arrayWithObject: @"wfda04917012@gmail.com"];
    [mailPicker setToRecipients: toRecipients];
    /** 添加抄送*/
    NSArray *ccRecipients = [NSArray arrayWithObjects:@"first@example.com", nil];
    [mailPicker setCcRecipients:ccRecipients];
    /** 添加密送*/
    NSArray *bccRecipients = [NSArray arrayWithObjects:@"fourth@example.com", nil];
    [mailPicker setBccRecipients:bccRecipients];
    
    /** 添加图片*/
    UIImage *addPic = [UIImage imageNamed: @"Icon@2x.png"];
    NSData *imageData = UIImagePNGRepresentation(addPic);
    [mailPicker addAttachmentData: imageData mimeType: @"" fileName: @"Icon.png"];

#if 0
    //添加一个pdf附件
    NSString *file = [self fullBundlePathFromRelativePath:@"高质量C++编程指南.pdf"];
    NSData *pdf = [NSData dataWithContentsOfFile:file];
    [mailPicker addAttachmentData: pdf mimeType: @"" fileName: @"高质量C++编程指南.pdf"];
#endif
    
    NSString *emailBody = @"<font color='red'>eMail</font> 测试邮件内容";
    [mailPicker setMessageBody:emailBody isHTML:YES];
    [self presentViewController:mailPicker animated:YES completion:nil];
    
}
/** alertMessage*/
-(void)alertWithMessage:(NSString *)messgae
{
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"注意" message:messgae delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [self performSelector:@selector(hideAlert:) withObject:alertView afterDelay:1];
    [alertView show];
}
/** alertHident*/
-(void)hideAlert:(UIAlertView *)alert
{
    [alert dismissWithClickedButtonIndex:0 animated:YES];
}

/** MFMailComposeViewController Delegate*/
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *msg;
    switch (result)
    {
        case MFMailComposeResultCancelled:
            msg = @"取消发送";
            break;
        case MFMailComposeResultSaved:
            msg = @"成功保存";
            break;
        case MFMailComposeResultSent:
            msg = @"发送成功";
            break;
        case MFMailComposeResultFailed:
            msg = @"发送失败";
            break;
        default:
            msg = @"服务器繁忙";
            break;
    }
    [self alertWithMessage:msg];
}

@end
