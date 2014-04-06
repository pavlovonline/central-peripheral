//
//  ChooseRoleViewController.m
//  BluetoothTest
//
//  Created by Anton Pavlov on 3/25/14.
//  Copyright (c) 2014 Anton Pavlov. All rights reserved.
//

#import "ChooseRoleViewController.h"
#import "CentralViewController.h"
#import "PeripheralViewController.h"

@interface ChooseRoleViewController ()

@end

@implementation ChooseRoleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGFloat buttonWidth = 70.0f;
    CGFloat buttonHeight = 40.0f;
    
    self.navigationController.edgesForExtendedLayout = UIRectEdgeNone;
    
    UIButton *centralButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [centralButton setFrame:CGRectMake(((self.view.bounds.size.width - buttonWidth) / 2), ((self.view.bounds.size.height - (buttonHeight*2)) / 4), buttonWidth, buttonHeight)];
    [centralButton setTitle:@"Central" forState:UIControlStateNormal];
    [centralButton addTarget:self action:@selector(centralChosen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:centralButton];
    
    UIButton *peripheralButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [peripheralButton setFrame:CGRectMake(((self.view.bounds.size.width - buttonWidth) / 2), (self.view.bounds.size.height -((self.view.bounds.size.height - (buttonHeight * 2)) / 4)), buttonWidth, buttonHeight)];
    [peripheralButton setTitle:@"Peripheral" forState:UIControlStateNormal];
    [peripheralButton addTarget:self action:@selector(peripheralChosen) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:peripheralButton];
}


- (void)centralChosen {
    CentralViewController *aCentralViewController = [[CentralViewController alloc] init];
    [self.navigationController pushViewController:aCentralViewController animated:YES];
}


- (void)peripheralChosen {
    PeripheralViewController *aPeripheralViewController = [[PeripheralViewController alloc] init];
    [self.navigationController pushViewController:aPeripheralViewController animated:YES];
}

@end
