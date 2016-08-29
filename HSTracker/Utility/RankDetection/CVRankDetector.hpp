//
//  CVRankDetector.hpp
//  HSTracker
//
//  Created by Matthew Welborn on 6/17/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#ifndef CVRankDetector_hpp
#define CVRankDetector_hpp

// Apple's check macro messes with openCV
#undef check
#include <opencv2/opencv.hpp>
#include <opencv2/xfeatures2d.hpp>
#define check(assertion) __Check(assertion)

class CVRankDetector {
    
public:
    CVRankDetector();
    int detectRank(std::string);
    bool getDidInit();
    
private:
    const double ratio_test_ratio = 0.6;
    const int nmatches_threshold  = 10;
    
    std::vector<cv::Mat> descriptorsForRank;
    cv::Ptr<cv::Feature2D> detector;
    
    bool didInit = false;
    
};

#endif /* CVRankDetector_hpp */