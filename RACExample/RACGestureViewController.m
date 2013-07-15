//
//  RACGestureViewController.m
//  RACExample
//
//  Created by Terry Lewis II on 7/14/13.
//  Copyright (c) 2013 Terry Lewis. All rights reserved.
//

#import "RACGestureViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACGestureViewController ()
@property(weak, nonatomic) IBOutlet UILabel *translationLabel;
@property(weak, nonatomic) IBOutlet UILabel *stateLabel;

@end

@implementation RACGestureViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]init];
    [self.view addGestureRecognizer:panGesture];
    CGPoint originalCenter = self.view.center;
    ///The value we really care about is the translation value, so that is what we return.
    RACSignal *panGestureSignal = [panGesture.rac_gestureSignal map:^id(UIPanGestureRecognizer *recognizer) {
        CGPoint translation = [recognizer translationInView:recognizer.view];
        NSInteger yBoundary = MIN(recognizer.view.center.y + translation.y, originalCenter.y - 50);
        [recognizer setTranslation:CGPointZero inView:self.view];
        return [NSValue valueWithCGPoint:CGPointMake(recognizer.view.center.x, yBoundary)];
    }];
    ///We bind the center of the view to the values that are sent from the signal.
    RAC(self.view.center) = panGestureSignal;
    ///We want to keep track of the y value of the translation and display it in real time to the user, so we transform the value into a String and return that.
    RACSignal *panGestureString = [panGestureSignal map:^id(NSValue *value) {
        return [NSString stringWithFormat:@"Y Translation = %f", value.CGPointValue.y];
    }];
    ///We also want real time information about the state of the gesture, so we transform that into a String as well.
    RACSignal *panGestureState = [panGesture.rac_gestureSignal map:^id(UIPanGestureRecognizer *recognizer) {
        NSString *state;
        switch(recognizer.state) {
            case UIGestureRecognizerStateChanged:
                state = @"Gesture is Changed";
                break;
            case UIGestureRecognizerStateEnded:
                state = @"Gesture is Ended";
                break;
            default:
                break;
        }
        return state;
    }];
    ///We want a different color to represent the state of the gesture, so we use the states as keys.
    NSDictionary *colors = @{@(UIGestureRecognizerStateEnded) : [UIColor blueColor], @(UIGestureRecognizerStateChanged) : [UIColor purpleColor]};
    ///Here we filter the values, and only return a color from our dictionary when the state is one of the ones we care about.
    RACSignal *colorSignal = [[panGesture.rac_gestureSignal filter:^BOOL(UIPanGestureRecognizer *recognizer) {
        return (recognizer.state == UIGestureRecognizerStateChanged || recognizer.state == UIGestureRecognizerStateEnded);
    }]map:^id(UIPanGestureRecognizer *recognizer) {
        return colors[@(recognizer.state)];
    }];
    ///We want the starting point displayed when the view loads.
    NSString *initialPoint = [NSString stringWithFormat:@"Y Translation = %f", originalCenter.y];
    ///+[RACSignal merge] takes an array of signals and returns a value each time one of the signals fires. Here the initialPoint immediatly returns, thus the label is set when the view loads. Then afterwards, the panGestureSignal will be sending its values when it is activated.
    RAC(self.translationLabel.text) = [RACSignal merge:@[panGestureString, [RACSignal return:initialPoint]]];
    ///The label will always reflect the current state of the recognizer.
    RAC(self.stateLabel.text) = panGestureState;
    ///The color will be updated each time the signal returns a value.
    RAC(self.view.backgroundColor) = colorSignal;
}


@end