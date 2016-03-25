//
//  XIUsersListVC.m
//  XIUsersList
//
//  Created by xi on 16/3/24.
//  Copyright © 2016年 xi. All rights reserved.
//

#import "XIUsersListVC.h"

@interface XIUser : NSObject
@property (nonatomic , copy) NSString *name;
@property (nonatomic , copy) NSString *pinyinName;
@property (nonatomic , assign) BOOL isStar;
@end

@implementation XIUser

- (NSString *)pinyinName {
    return [NSString pinyinOfString:_name];
}

@end

#define kCellIdentifier_UserCell @"UserCell"

typedef void(^starSomeoneBlock)(XIUser *user,UISwitch *switcher);

@interface XIUserCell : UITableViewCell

@property (nonatomic , strong) XIUser   *user;
@property (nonatomic , strong) UISwitch *switcher;
@property (nonatomic , copy  ) starSomeoneBlock starSomeone;

- (void)starSomeone:(starSomeoneBlock)starSomeone;

@end

@implementation XIUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        if (!_switcher) {
            _switcher = [UISwitch new];
            [_switcher sizeToFit];
            _switcher.centerY = [XIUserCell cellHeight]/2;
            _switcher.centerX = kScreenWidth - _switcher.width;
            [_switcher addTarget:self action:@selector(handler:) forControlEvents:UIControlEventValueChanged];
            [self.contentView addSubview:_switcher];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.text = _user.name;
    [_switcher setOn:_user.isStar];
}

- (void)handler:(id)sender {
    if (_starSomeone) {
        _starSomeone(_user,sender);
    }
}

- (void)starSomeone:(starSomeoneBlock)starSomeone {
    if (starSomeone) {
        _starSomeone = starSomeone;
    }
}

+ (CGFloat)cellHeight {
    return 57;
}

@end

@interface XIUsersListVC ()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UISearchDisplayDelegate>

@property (nonatomic , strong) UITableView *rootTable;
@property (nonatomic , strong) UISearchBar *searchBar;
@property (nonatomic , strong) UISearchDisplayController *searchTable;
@property (nonatomic , strong) NSMutableArray *searchResults;
@property (nonatomic , strong) NSDictionary *userGroups;

@end

@implementation XIUsersListVC

- (id)init {
    self = [super init];
    if (self) {
        _usersListType = arc4random()%3 + 1;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.view.userInteractionEnabled = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.view.userInteractionEnabled = NO;
    if (_usersListType) {
        switch (_usersListType) {
            case UsersListTypeFriends:
                self.navigationItem.title = @"Friends";
                break;
            case UsersListTypeFans:
                self.navigationItem.title = @"Fans";
                break;
            case UsersListTypeStars:
                self.navigationItem.title = @"Stars";
                break;
        }
    }
    
    _rootTable = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        tableView.sectionIndexTrackingBackgroundColor = [UIColor clearColor];
        tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x666666"];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.estimatedRowHeight = [XIUserCell cellHeight];
        [tableView registerClass:[XIUserCell class] forCellReuseIdentifier:kCellIdentifier_UserCell];
        [self.view addSubview:tableView];
        tableView;
    });
    _searchBar = ({
        UISearchBar *searchBar = [UISearchBar new];
        searchBar.size = CGSizeMake(kScreenWidth, 40);
        searchBar.placeholder = @"昵称/用户名";
        searchBar.delegate = self;
        _rootTable.tableHeaderView = searchBar;
        searchBar;
    });
    _searchTable = ({
        UISearchDisplayController *searchDisplayVC = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
        searchDisplayVC.delegate = self;
        searchDisplayVC.searchResultsDataSource = self;
        searchDisplayVC.searchResultsDelegate = self;
        [searchDisplayVC.searchResultsTableView registerClass:[XIUserCell class] forCellReuseIdentifier:kCellIdentifier_UserCell];
        searchDisplayVC;
    });
    
    [self requestData];
}

- (void)requestData {
    //简单数据源
    NSArray *data = @[@{@"name":@"大军",@"isStar":@(NO)},
                      @{@"name":@"凯子",@"isStar":@(NO)},
                      @{@"name":@"色东",@"isStar":@(NO)},
                      @{@"name":@"骚伟",@"isStar":@(YES)}];
    NSArray *array = [NSArray modelArrayWithClass:[XIUser class] json:data];
    _userGroups = [self groupUsersByPinyinFrom:array];
}

- (NSDictionary *)groupUsersByPinyinFrom:(NSArray *)array {
    if (array.count <= 0) {
        return @{@"#":[NSMutableArray array]};
    }
    NSMutableDictionary *groups = [NSMutableDictionary dictionary];
    NSMutableArray *allkeys = [NSMutableArray array];
    for (char c = 'A'; c < 'Z'+1; c++) {
        char key[2];
        key[0] = c;
        key[1] = '\0';
        [allkeys addObject:[NSString stringWithUTF8String:key]];
    }
    [allkeys addObject:@"#"];
    for (NSString *key in allkeys) {
        [groups setObject:[NSMutableArray array] forKey:key];
    }
    [array enumerateObjectsUsingBlock:^(XIUser *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *keyStr = nil;
        NSMutableArray *keyArray = nil;
        if (obj.pinyinName.length > 1) {
            keyStr = [obj.pinyinName substringToIndex:1];
            if ([[groups allKeys] containsObject:keyStr]) {
                keyArray = [groups objectForKey:keyStr];
            }
        }
        if (!keyArray) {
            keyStr = @"#";
            keyArray = [groups objectForKey:keyStr];
        }
        [keyArray addObject:obj];
        [groups setObject:keyArray forKey:keyStr];
    }];
    
    for (NSString *key in allkeys) {
        NSMutableArray *keyArray = [groups objectForKey:key];
        if (keyArray.count <= 0) {
            [groups removeObjectForKey:key];
        } else if (keyArray.count > 1){
            [keyArray sortUsingComparator:^NSComparisonResult(XIUser *obj1,XIUser *obj2) {
                return [obj1.pinyinName compare:obj2.pinyinName];
            }];
        }
    }
    
    return groups;
}

- (NSArray *)groupKeys {
    if (_userGroups.count <= 0) {
        return nil;
    }
    NSMutableArray *keys = [NSMutableArray arrayWithArray:_userGroups.allKeys];
    [keys sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    if ([keys containsObject:@"#"]) {
        [keys removeObject:@"#"];
        [keys addObject:@"#"];
    }
    [keys insertObject:UITableViewIndexSearch atIndex:0];
    return keys;
}



#pragma mark - *UITableViewDelegate/DataSource
-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == _rootTable) {
        return [self groupKeys];
    } else {
        return nil;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == _rootTable) {
        if ([self groupKeys].count > section && section > 0) {
            return [self groupKeys][section];
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (index == 0) {
        [tableView scrollToTopAnimated:NO];
        return NSNotFound;
    }
    return index;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections;
    if (tableView == _rootTable) {
        if (_userGroups) {
            sections = _userGroups.allKeys.count + 1;
        } else {
            sections = 1;
        }
    } else {
        sections = 1;
    }
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows;
    if (tableView == _rootTable) {
        if ([self groupKeys] && [[self groupKeys] count] > section) {
            rows = [[_userGroups objectForKey:[self groupKeys][section]] count];
        } else {
            rows = 0;
        }
    } else {
        rows = _searchResults.count;
    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XIUserCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_UserCell forIndexPath:indexPath];
    XIUser *currentUser;
    if (tableView != _rootTable) {
        currentUser = _searchResults[indexPath.row];
    } else {
        currentUser = [_userGroups objectForKey:[self groupKeys][indexPath.section]][indexPath.row];
    }
    cell.user = currentUser;
    [cell starSomeone:^(XIUser *user, UISwitch *switcher) {
        user.isStar = switcher.isOn;
        [self showMessage:[NSString stringWithFormat:@"%@%@",user.isStar ? @"关注了" : @"取消关注",user.name]];
    }];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    CGFloat height = [self tableView:tableView heightForHeaderInSection:section];
    if (height <= 0) {
        return nil;
    }
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, height)];
    header.backgroundColor = [UIColor colorWithHexString:@"0xeeeeee"];
    
    UILabel *title = [[UILabel alloc] init];
    title.font = [UIFont systemFontOfSize:12];
    title.textColor = [UIColor colorWithHexString:@"0x999999"];
    title.text = [self tableView:tableView titleForHeaderInSection:section];
    title.height = height;
    title.width = kScreenWidth - 20;
    title.left = 10;
    title.top = 0;
    [header addSubview:title];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView == _rootTable) {
        if (section == 0) {
            return 0;
        }
        return 20;
    }else{
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [XIUserCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - *UISearchBarDelegate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self setSearchBar:searchBar backgroudColor:[UIColor redColor]];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [self setSearchBar:searchBar backgroudColor:nil];
    return YES;
}

#pragma mark - *UISearchDisplayDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self updateFilteredContentForSearchString:searchString];
    return YES;
}

#pragma mark - *OtherMethods
- (void)setSearchBar:(UISearchBar *)searchBar backgroudColor:(UIColor *)color {
    static NSInteger customBgTag = 999;
    UIView *realView = [[searchBar subviews] firstObject];
    [[realView subviews] enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        if (obj.tag == customBgTag) {
            [obj removeFromSuperview];
        }
    }];
    if (color) {
        UIImageView *customBg = [[UIImageView alloc] initWithImage:[UIImage imageWithColor:color size:CGSizeMake(CGRectGetWidth(searchBar.frame), CGRectGetHeight(searchBar.frame) + 20)]];
        [customBg setTop:-20];
        customBg.tag = customBgTag;
        [[[searchBar subviews] firstObject] insertSubview:customBg atIndex:1];
    }
}

- (void)updateFilteredContentForSearchString:(NSString *)searchString{
    // start out with the entire list
    NSMutableArray *array = [NSMutableArray array];
    for (NSArray *users in [_userGroups allValues]) {
        [array addObjectsFromArray:users];
    }
    _searchResults = [array mutableCopy];
    // strip out all the leading and trailing spaces
    NSString *strippedStr = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // break up the search terms (separated by spaces)
    NSArray *searchItems = nil;
    if (strippedStr.length > 0)
    {
        searchItems = [strippedStr componentsSeparatedByString:@" "];
    }
    
    // build all the "AND" expressions for each value in the searchString
    NSMutableArray *andMatchPredicates = [NSMutableArray array];
    
    for (NSString *searchString in searchItems)
    {
        // each searchString creates an OR predicate for: name, global_key
        NSMutableArray *searchItemsPredicate = [NSMutableArray array];
        
        // name field matching
        NSExpression *lhs = [NSExpression expressionForKeyPath:@"name"];
        NSExpression *rhs = [NSExpression expressionForConstantValue:searchString];
        NSPredicate *finalPredicate = [NSComparisonPredicate
                                       predicateWithLeftExpression:lhs
                                       rightExpression:rhs
                                       modifier:NSDirectPredicateModifier
                                       type:NSContainsPredicateOperatorType
                                       options:NSCaseInsensitivePredicateOption];
        [searchItemsPredicate addObject:finalPredicate];
        //        pinyinName field matching
        lhs = [NSExpression expressionForKeyPath:@"pinyinName"];
        rhs = [NSExpression expressionForConstantValue:searchString];
        finalPredicate = [NSComparisonPredicate
                          predicateWithLeftExpression:lhs
                          rightExpression:rhs
                          modifier:NSDirectPredicateModifier
                          type:NSContainsPredicateOperatorType
                          options:NSCaseInsensitivePredicateOption];
        [searchItemsPredicate addObject:finalPredicate];
        // at this OR predicate to ourr master AND predicate
        NSCompoundPredicate *orMatchPredicates = (NSCompoundPredicate *)[NSCompoundPredicate orPredicateWithSubpredicates:searchItemsPredicate];
        [andMatchPredicates addObject:orMatchPredicates];
    }
    
    NSCompoundPredicate *finalCompoundPredicate = (NSCompoundPredicate *)[NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
    
    self.searchResults = [[self.searchResults filteredArrayUsingPredicate:finalCompoundPredicate] mutableCopy];
}

- (void)showMessage:(NSString *)message {
    YYLabel *msg = [YYLabel new];
    msg.text = message;
    msg.textColor = [UIColor whiteColor];
    msg.backgroundColor = [UIColor redColor];
    msg.font = [UIFont systemFontOfSize:16];
    msg.width = self.view.width;
    msg.height = [msg.text heightForFont:msg.font width:self.view.width] + 20;
    msg.left = 0;
    msg.top  = 64 - msg.height;
    msg.textAlignment = NSTextAlignmentCenter;
    msg.textVerticalAlignment = YYTextVerticalAlignmentCenter;
    msg.alpha = 0;
    [self.view addSubview:msg];
    
    [UIView animateWithDuration:0.3 animations:^{
        msg.alpha = 1;
        msg.top = 64;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            msg.top = 64 - msg.height;
            msg.alpha = 0;
        } completion:^(BOOL finished) {
            [msg removeFromSuperview];
        }];
    }];
    
}

- (void)dealloc {
    _rootTable.delegate = nil;
    _rootTable.dataSource = nil;
}

@end
