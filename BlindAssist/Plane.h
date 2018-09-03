//
//  Plane.h
//  BlindAssist
//
//  Created by Giovanni Terlingen on 03/09/2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import <ARKit/ARKit.h>

@interface Plane : SCNNode

@property SCNNode *meshNode;

- (id)init:(ARPlaneAnchor*)anchor in:(ARSCNView*)sceneView;

@end
