//
//  FinishingViewController.h
//  hw3
//
//  Created by student14 on 2021/10/27.
//  Copyright © 2021 SDCS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChoiceCell.h"
#import "../../Pods/Masonry/Masonry/Masonry.h"

@interface ChoiceCell()

@end

@implementation ChoiceCell
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self)
    {
        self.layer.borderWidth = 0;
        self.layer.cornerRadius = 15;
        _choice = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _choice.textAlignment = NSTextAlignmentCenter;
        _choice.textColor = [UIColor blackColor];
        _choice.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
        [self.contentView addSubview:_choice];
        [_choice mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(285, 55));
            make.centerX.equalTo(self);
            make.centerY.equalTo(self);
        }];
    }
    return self;
}


@end
