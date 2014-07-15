//
//  GMBLibraryTableViewController.m
//  Obelisk
//
//  Created by Garret Buell on 6/14/14.
//
//

#import "GMBLibraryTableViewController.h"
#import "GMBVideoItem.h"
#import "AFHTTPRequestOperationManager.h"
#import "GMBChromecastManager.h"
#import "GMBUtility.h"
#import "TFHpple.h"

@interface GMBLibraryTableViewController ()

@property NSMutableArray *libraryItems;

@end

@implementation GMBLibraryTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.libraryItems = [[NSMutableArray alloc] init];

  [self loadLibrary];
  [self loadObelisk];

  [[GMBChromecastManager sharedManager] startDeviceScan];

  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;

  // Uncomment the following line to display an Edit button in the navigation
  // bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (IBAction)dropDown:(UIButton *)sender {
  NSLog(@"dropDown IBAction called");
  // [self animateHeaderViewWithText:@"This is my test string"];
}

- (void)loadObelisk {
  // [self.libraryItems removeAllObjects];

  AFHTTPRequestOperationManager *manager =
      [AFHTTPRequestOperationManager manager];
  manager.responseSerializer = [AFHTTPResponseSerializer serializer];
  NSMutableOrderedSet *allFolders = [[NSMutableOrderedSet alloc] init];
  NSMutableOrderedSet *allFiles = [[NSMutableOrderedSet alloc] init];
  [manager GET:@"http://obelisk.local/Movies/"
      parameters:nil
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          TFHpple *doc = [[TFHpple alloc] initWithHTMLData:responseObject];
          NSArray *results = [[doc searchWithXPathQuery:@"//a/@href"]
              bk_map:^(TFHppleElement *e) { return e.text; }];
          NSError *error = NULL;
          NSRegularExpression *fileRegex = [NSRegularExpression
              regularExpressionWithPattern:@".+\\.mkv$"
                                   options:NSRegularExpressionCaseInsensitive
                                     error:&error];
          [results bk_each:^(NSString *href) {
              if ([href isEqualToString:@"../"]) {
                return;
              }
              if ([fileRegex firstMatchInString:href
                                        options:0
                                          range:NSMakeRange(
                                                    0, [href length])] != nil) {
                [allFiles addObject:href];
              } else {
                [allFolders addObject:href];
              }
          }];
          [allFolders
              bk_each:^(NSString *href) { NSLog(@"Folder: %@", href); }];
          // GMBVideoItem *lineItem = [[GMBVideoItem alloc] init];
          // lineItem.size = @"size";
          // lineItem.title = @"title";
          //[self.libraryItems addObject:lineItem];
          //[self.tableView reloadData];
      }
      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          [GMBUtility
              showDropdownNotification:
                  [NSString
                      stringWithFormat:@"Error fetching library: %@", error]];
          NSLog(@"Error: %@", error);
      }];
}

- (void)loadLibrary {
  [self.libraryItems removeAllObjects];

  AFHTTPRequestOperationManager *manager =
      [AFHTTPRequestOperationManager manager];
  manager.responseSerializer = [AFHTTPResponseSerializer serializer];
  [manager GET:@"http://gmbuell.com/library.txt"
      parameters:nil
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          NSString *libraryText =
              [[NSString alloc] initWithData:responseObject
                                    encoding:NSUTF8StringEncoding];
          NSLog(@"Response: %@", libraryText);
          NSArray *lines = [libraryText componentsSeparatedByString:@"\n"];
          [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx,
                                              BOOL *stop) {
              NSArray *components = [line componentsSeparatedByString:@" "];
              if ([components count] != 2) {
                return;
              }
              GMBVideoItem *lineItem = [[GMBVideoItem alloc] init];
              lineItem.size = components[0];
              lineItem.title = components[1];
              [self.libraryItems addObject:lineItem];
          }];
          [self.tableView reloadData];
      }
      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          [GMBUtility
              showDropdownNotification:
                  [NSString
                      stringWithFormat:@"Error fetching library: %@", error]];
          NSLog(@"Error: %@", error);
      }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // Return the number of sections.
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return (int)[self.libraryItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"LibraryPrototypeCell"
                                      forIndexPath:indexPath];

  // Configure the cell...
  GMBVideoItem *item =
      [self.libraryItems objectAtIndex:(unsigned int)indexPath.row];
  cell.textLabel.text =
      [NSString stringWithFormat:@"%@ (%@)", item.title, item.size];

  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  GMBVideoItem *item =
      [self.libraryItems objectAtIndex:(unsigned int)indexPath.row];
  [[GMBChromecastManager sharedManager] castVideo:item];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath
*)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath]
withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the
array, and add a new row to the table view
    }
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath
*)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath
*)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little
preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
