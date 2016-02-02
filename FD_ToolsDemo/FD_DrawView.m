
//
//  FD_DrawView.m
//  FD_ToolsDemo
//
//  Created by 阿东 on 15/12/7.
//  Copyright © 2015年 WFD. All rights reserved.
//

#import "FD_DrawView.h"

@implementation FD_DrawView

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] set];
    CGContextFillRect(context, rect);
    
    /*边框圆
     */
    CGContextSetRGBStrokeColor(context, 255/255.0, 106/255.0, 0/255.0, 1);
    CGContextSetLineWidth(context, 5);
    CGContextAddArc(context, 50, 70, 20, 0, 2*M_PI, 0);
    CGContextDrawPath(context, kCGPathStroke);
}

@end
