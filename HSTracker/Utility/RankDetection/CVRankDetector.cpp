//
//  CVRankDetector.cpp
//  HSTracker
//
//  Created by Matthew Welborn on 6/17/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#include "CVRankDetector.hpp"

#include <iostream>
#include <corefoundation/corefoundation.h>


CVRankDetector::CVRankDetector() {
    didInit = false;
    try {
        detector = cv::xfeatures2d::SIFT::create();
        
        CFBundleRef mainBundle = CFBundleGetMainBundle();
        CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
        
        char path[PATH_MAX];
        if (!CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8 *)path, PATH_MAX))
        {
            std::cerr << "Failed to load rank images, CV rank detection will fail" << std::endl;
        }
        CFRelease(resourcesURL);
        
        for(int test_rank = 0; test_rank <= 25; test_rank++)
        {
            std::ostringstream string;
            string << path << "/CV" << test_rank << ".png";
            
            cv::Mat img_rank = cv::imread(string.str(), 0);
            
            std::vector<cv::KeyPoint> keypoints_rank;
            detector->detect(img_rank, keypoints_rank);
            
            cv::Mat descriptors_rank;
            detector->compute(img_rank, keypoints_rank, descriptors_rank);
            
            descriptorsForRank.push_back(descriptors_rank);
        }
        
        didInit = true;
    }
    catch (const std::length_error& e)
    {
        std::cerr << "Error: Failed to initialize CVRankDetector" << std::endl;
        std::cerr << "Caught std::length_error what=" << e.what() << std::endl;
        didInit = false;
    }
}

int CVRankDetector::detectRank(std::string tempfile)
{
    if (!didInit)
    {
        std::cerr << "Error: Called detectRank on uninitialized CVRankDetector." << std::endl;
        return -2;
    }
    
    try
    {
        cv::Mat img_screen = cv::imread(tempfile,0);
        
        cv::Ptr<cv::Feature2D> detector = cv::xfeatures2d::SIFT::create();
        
        std::vector<cv::KeyPoint> keypoints_screen;
        detector->detect(img_screen, keypoints_screen);
        
        cv::Mat descriptors_screen;
        detector->compute(img_screen, keypoints_screen, descriptors_screen);
        
        int best_match = 0;
        int best_rank = 0;
        
        for(int test_rank = 0; test_rank <= 25; test_rank++)
        {
            cv::FlannBasedMatcher matcher;
            std::vector< std::vector<cv::DMatch> > matches;
            
            matcher.knnMatch(descriptors_screen, descriptorsForRank[test_rank], matches, 2);
            
            std::vector<cv::DMatch> good_matches;
            for (int i=0; i<matches.size(); i++)
            {
                cv::DMatch nn1 = matches[i][0];
                cv::DMatch nn2 = matches[i][1];
                
                if (nn1.distance < ratio_test_ratio*nn2.distance)
                {
                    good_matches.push_back(matches[i][0]);
                }
            }
            
            // std::cout << "Matches for rank " << test_rank << ": " << good_matches.size()  << std::endl;
            
            if (good_matches.size() > best_match) {
                best_match = int(good_matches.size());
                best_rank = test_rank;
            }
        }
        
        if (best_match > nmatches_threshold) {
            return best_rank;
        } else {
            return -1;
        }
    }
    catch (const std::length_error& e)
    {
        std::cerr << "Caught std::length_error in detectRank, what=" << e.what() << std::endl;
        return -3;
    }
}

bool CVRankDetector::getDidInit()
{
    return didInit;
}