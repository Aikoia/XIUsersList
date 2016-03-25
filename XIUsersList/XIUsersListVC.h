//
//  XIUsersListVC.h
//  XIUsersList
//
//  Created by xi on 16/3/24.
//  Copyright © 2016年 xi. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,UsersListType) {
    UsersListTypeFriends    = 1,
    UsersListTypeFans,
    UsersListTypeStars,
};
@interface XIUsersListVC : UIViewController

@property (nonatomic , assign) UsersListType usersListType;

@end
