//
//  CardMissingDetector.cpp
//  HSTracker
//
//  Created by Benjamin Michotte on 31/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#include "CardMissingDetector.hpp"

#include <iostream>
#include <corefoundation/corefoundation.h>

CardMissingDetector::CardMissingDetector() {
    didInit = false;
    try {
        detector = cv::xfeatures2d::SIFT::create();

        CFBundleRef mainBundle = CFBundleGetMainBundle();
        CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);

        char path[PATH_MAX];
        if (!CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8 *)path, PATH_MAX))
        {
            std::cerr << "Failed to load cards images, card detection will fail" << std::endl;
        }
        CFRelease(resourcesURL);

        for(int test_lock = 0; test_lock <= 1; test_lock++)
        {
            std::ostringstream string;
            string << path << "/lock_" << test_lock << ".png";

            cv::Mat img_lock = cv::imread(string.str(), 0);

            std::vector<cv::KeyPoint> keypoints_lock;
            detector->detect(img_lock, keypoints_lock);

            cv::Mat descriptors_lock;
            detector->compute(img_lock, keypoints_lock, descriptors_lock);

            descriptorsForLocks.push_back(descriptors_lock);
        }

        didInit = true;
    }
    catch (const std::length_error& e)
    {
        std::cerr << "Error: Failed to initialize CardMissingDetector" << std::endl;
        std::cerr << "Caught std::length_error what=" << e.what() << std::endl;
        didInit = false;
    }
}

int CardMissingDetector::detectLocks(std::string tempfile)
{
    if (!didInit)
    {
        std::cerr << "Error: Called detectLocks on uninitialized CardMissingDetector." << std::endl;
        return -2;
    }

    try
    {
        cv::Mat img_screen = cv::imread(tempfile, 0);

        cv::Ptr<cv::Feature2D> detector = cv::xfeatures2d::SIFT::create();

        std::vector<cv::KeyPoint> keypoints_screen;
        detector->detect(img_screen, keypoints_screen);

        cv::Mat descriptors_screen;
        detector->compute(img_screen, keypoints_screen, descriptors_screen);

        int best_match = 0;
        int best_lock = 0;

        for(int test_lock = 0; test_lock <= 1; test_lock++)
        {
            cv::FlannBasedMatcher matcher;
            std::vector< std::vector<cv::DMatch> > matches;

            matcher.knnMatch(descriptors_screen, descriptorsForLocks[test_lock], matches, 2);

            std::vector<cv::DMatch> good_matches;
            for (int i=0; i<matches.size(); i++)
            {
                cv::DMatch nn1 = matches[i][0];
                cv::DMatch nn2 = matches[i][1];

                if (nn1.distance < ratio_test_ratio * nn2.distance)
                {
                    good_matches.push_back(matches[i][0]);
                }
            }

            // std::cout << "Matches for rank " << test_lock << ": " << good_matches.size()  << std::endl;

            if (good_matches.size() > best_match) {
                best_match = int(good_matches.size());
                best_lock = test_lock;
            }
        }

        if (best_match > nmatches_threshold) {
            return best_lock;
        } else {
            return -1;
        }
    }
    catch (const std::length_error& e)
    {
        std::cerr << "Caught std::length_error in detectLocks, what=" << e.what() << std::endl;
        return -3;
    }
}

bool CardMissingDetector::getDidInit()
{
    return didInit;
}
