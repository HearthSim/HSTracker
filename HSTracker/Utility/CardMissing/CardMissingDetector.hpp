//
//  CardMissingDetector.hpp
//  HSTracker
//
//  Created by Benjamin Michotte on 31/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#ifndef CardMissingDetector_hpp
#define CardMissingDetector_hpp

// Apple's check macro messes with openCV
#undef check
#include <opencv2/opencv.hpp>
#include <opencv2/xfeatures2d.hpp>
#define check(assertion) __Check(assertion)

class CardMissingDetector {

    public:
    CardMissingDetector();
    int detectLocks(std::string);
    bool getDidInit();

    private:
    const double ratio_test_ratio = 0.6;
    const int nmatches_threshold  = 10;

    std::vector<cv::Mat> descriptorsForLocks;
    cv::Ptr<cv::Feature2D> detector;

    bool didInit = false;

};

#endif /* CardMissingDetector_hpp */
