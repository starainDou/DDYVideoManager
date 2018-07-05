#import "ViewController.h"
#import "DDYAuthorityManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *takeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"take" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor lightGrayColor]];
        [button addTarget:self action:@selector(handleTake) forControlEvents:UIControlEventTouchUpInside];
        [button setFrame:CGRectMake(0, 100, 120, 30)];
        button;
    });
    [self.view addSubview:takeButton];
}

- (void)handleTake {
    [DDYAuthorityManager ddy_CameraAuthAlertShow:YES result:^(BOOL isAuthorized, AVAuthorizationStatus authStatus) {
        [DDYAuthorityManager ddy_AudioAuthAlertShow:YES result:^(BOOL isAuthorized, AVAuthorizationStatus authStatus) {
            UIViewController *vc = [NSClassFromString(@"DDYCameraController") new];
            [self presentViewController:vc animated:YES completion:^{ }];
        }];
    }];
    
}

@end
