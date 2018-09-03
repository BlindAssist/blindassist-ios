//
//  Plane.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 03/09/2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import "Plane.h"
#import <math.h>

@implementation Plane

- (id)init:(ARPlaneAnchor*)anchor in:(ARSCNView*)sceneView {
    // Create a mesh to visualize the estimated shape of the plane.
    ARSCNPlaneGeometry *meshGeometry = [ARSCNPlaneGeometry planeGeometryWithDevice:sceneView.device];
    [meshGeometry updateFromPlaneGeometry:anchor.geometry];
    self.meshNode = [SCNNode nodeWithGeometry:meshGeometry];
    
    self = [super init];
    
    // Add the plane extent and plane geometry as child nodes so they appear in the scene.
    [super addChildNode:self.meshNode];
    
    return self;
}

-(void)setupMeshVisualStyle {
    // Make the plane visualization semitransparent to clearly show real-world placement.
    self.meshNode.opacity = 0.4f;
    
    SCNMaterial *material = self.meshNode.geometry.firstMaterial;
    material.diffuse.contents = [UIColor colorNamed:@"appYellow"];
    material.blendMode = SKBlendModeAdd;
}

@end
