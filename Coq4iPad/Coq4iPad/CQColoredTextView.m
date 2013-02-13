//
//  CQColoredTextView.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/13/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQColoredTextView.h"
#import <CoreText/CoreText.h>

@implementation CQColoredTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// from: https://github.com/KayK/RegexHighlightView/

-(void)drawRect:(CGRect)rect {
    self.textColor = [UIColor clearColor];
    
    if(self.text.length<=0) {
        self.text = @"";
        return;
    }
    
    //Prepare View for drawing
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context,CGAffineTransformIdentity);
    CGContextTranslateCTM(context,0,([self bounds]).size.height);
    CGContextScaleCTM(context,1.0,-1.0);
    
    //Get the view frame size
    CGSize size = self.frame.size;
    
    //Determine default text color
    UIColor* textColor = nil;
    if([self.textColor isEqual:[UIColor clearColor]]) {
        textColor = [UIColor blackColor];
    } else textColor = self.textColor;
    
    //Set line height, font, color and break mode
    CGFloat minimumLineHeight = [self.text sizeWithFont:self.font].height, maximumLineHeight = minimumLineHeight;
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)self.font.fontName,self.font.pointSize,NULL);
    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    
    //Apply paragraph settings
    CTParagraphStyleRef style = CTParagraphStyleCreate((CTParagraphStyleSetting[3]){
        {kCTParagraphStyleSpecifierMinimumLineHeight,sizeof(minimumLineHeight),&minimumLineHeight},
        {kCTParagraphStyleSpecifierMaximumLineHeight,sizeof(maximumLineHeight),&maximumLineHeight},
        {kCTParagraphStyleSpecifierLineBreakMode,sizeof(CTLineBreakMode),&lineBreakMode}
    },3);
    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)font,(NSString*)kCTFontAttributeName,(__bridge id)textColor.CGColor,(NSString*)kCTForegroundColorAttributeName,(__bridge id)style,(NSString*)kCTParagraphStyleAttributeName,nil];
    
    int MARGIN = 8;
    
    //Create path to work with a frame with applied margins
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path,NULL,CGRectMake(MARGIN+0.0,(-self.contentOffset.y+0),(size.width-2*MARGIN),(size.height+self.contentOffset.y-MARGIN)));
    
    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attributes];
    if(self.coloringFun) self.coloringFun(text);
    
    //Create attributed string, with applied syntax highlighting
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)text;
    
    //Draw the frame
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0,CFAttributedStringGetLength(attributedString)),path,NULL);
    CTFrameDraw(frame,context);
}


@end
