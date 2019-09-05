//
//  MKCameraFilterView.h
//  MagicCamera
//
//  Created by mkil on 2019/9/4.
//  Copyright © 2019 黎宁康. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MKFilterModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MKCameraFilterView : UIView

@property(nonatomic, strong) NSArray<MKFilterModel *>* filterModel;

- (void)toggle;

@end

NS_ASSUME_NONNULL_END
