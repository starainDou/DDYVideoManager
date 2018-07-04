#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSDateFormatter *dateFomater = [[NSDateFormatter alloc]init];
    dateFomater.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS+aa";
    NSString *original = [dateFomater stringFromDate:[NSDate date]];
    NSLog(@"%@", original);
}

@end
