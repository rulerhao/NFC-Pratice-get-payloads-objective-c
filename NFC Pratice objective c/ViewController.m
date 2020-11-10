//
//  ViewController.m
//  NFC Pratice objective c
//
//  Created by louie on 2020/11/10.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UITextView *PayLoadsTextView;
@property (strong, nonatomic) IBOutlet UIButton *NFCScanButton;
@property (strong, nonatomic) NSData *PayLoad_Data;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _PayLoad_Data = [[NSData alloc] init];

}
// NFC Scan Button 被按下後
- (IBAction)NFCScanButtonBeTouchedDown:(id)sender
{
    NFCNDEFReaderSession *session = [[NFCNDEFReaderSession alloc] initWithDelegate:self
                                                                             queue:dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT)
                                                          invalidateAfterFirstRead:NO];
    [session beginSession];
}

- (void)
readerSession:(nonnull NFCNDEFReaderSession *)session
didDetectNDEFs:(nonnull NSArray<NFCNDEFMessage *> *)messages
{
    for (NFCNDEFMessage *message in messages)
    {
        for (NFCNDEFPayload *payload in message.records)
        {
            _PayLoad_Data = payload.payload;
        }
    }
    // 轉換為指定 format
    NSString *PayLoads_String = [self getHEX:_PayLoad_Data];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 輸出字串
        self->_PayLoadsTextView.text = [self translatePayLoadsToShowFormat : PayLoads_String];
        // 切換字型 讓所有 character 寬高相同
        self->_PayLoadsTextView.font = [UIFont fontWithName:@"Menlo-Bold" size:16];
        // 向左靠攏
        self->_PayLoadsTextView.textAlignment = NSTextAlignmentLeft;
    });
}

- (void)
readerSession:(nonnull NFCNDEFReaderSession *)session
didInvalidateWithError:(nonnull NSError *)error
{
    NSLog(@"Don't Know What To Do");
}

- (NSString *) translatePayLoadsToShowFormat : (NSString *) Origin_Payloads_String
{
    NSString *PayLoads_String = [self getHEX:_PayLoad_Data];
    // 取得前方補零 bytes 數
    NSString *Length_Before_Head_String = [self getSubString:PayLoads_String
                                             length:2
                                           location:10];
    
    NSUInteger Length_Before_Head_UInteger = [self getUIntegerFromHexString:Length_Before_Head_String];
    
    // 將該補的 bytes 補上
    NSString *New_PayLoads_String = PayLoads_String;
    for(NSUInteger i = 0; i < Length_Before_Head_UInteger; i++)
    {
        New_PayLoads_String = [self MergeTwoString:@"00" SecondStr:New_PayLoads_String];
    }
    
    NSLog(@"TotalString : %@", New_PayLoads_String);
    
    NSString *Appended_New_PayLoads_String = @"";
    for(NSUInteger i = 0; i < [New_PayLoads_String length] / 2; i++)
    {
        NSString *StringAtIndexI = [self getSubString:New_PayLoads_String
                                               length:2
                                             location:i * 2];
        
        Appended_New_PayLoads_String = [self MergeTwoString:Appended_New_PayLoads_String
                                                  SecondStr:StringAtIndexI];
        
        Appended_New_PayLoads_String = [self MergeTwoString:Appended_New_PayLoads_String
                                                  SecondStr:@" "];
        
        if(i % 8 == 7)
        {
            NSString* Text_String = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)i];
            // i
            Text_String = [self MergeTwoString:@"["
                                     SecondStr:Text_String];
            // [i
            Text_String = [self MergeTwoString:Text_String
                                     SecondStr:@"]"];
            // [i]
            
            Appended_New_PayLoads_String = [self MergeTwoString:Appended_New_PayLoads_String
                                                      SecondStr:Text_String];
        }
        
        if(i % 8 == 7)
        {
            Appended_New_PayLoads_String = [self MergeTwoString:Appended_New_PayLoads_String
                                                      SecondStr:@"\n"];
        }
    }
    return Appended_New_PayLoads_String;
}
/*!
 * @param data_bytes : 要被轉換為 Hex String 的 NSData
 *  @discussion
 *      將 NSData 轉換為 HexString
 *
 */
- (NSString *)getHEX:(NSData *)data_bytes
{
    const unsigned char *dataBytes = [data_bytes bytes];
    NSMutableString *ret = [NSMutableString stringWithCapacity:[data_bytes length] * 2];
    for (int i = 0; i<[data_bytes length]; ++i)
    [ret appendFormat:@"%02lX", (unsigned long)dataBytes[i]];
    return ret;
}

/*!
 * @param Ori_String : 要被切的 string
 * @param Length : 切下的長度
 * @param Location : 由第幾個開始切
 *  @discussion
 *      取得指定長度和位置的 Substring of string
 *
 */
- (NSString *)
getSubString    : (NSString *) Ori_String
length          : (NSUInteger) Length
location        : (NSUInteger) Location {
    NSRange search_Range;
    search_Range.length = Length;
    search_Range.location = Location;
    NSString *new_String = [Ori_String substringWithRange:search_Range];
    
    return new_String;
}

- (NSUInteger)
getUIntegerFromHexString : (NSString *) Hex_String
{
    unsigned int outVal;
        NSScanner* scanner = [NSScanner scannerWithString:Hex_String];
        [scanner scanHexInt:&outVal];
    return outVal;
}

- (NSString *)
MergeTwoString: (NSString *) First_Str
SecondStr     : (NSString *) Second_Str {
    NSString *Merged_String = [NSString stringWithFormat:@"%@%@", First_Str, Second_Str];
    return Merged_String;
}
@end
