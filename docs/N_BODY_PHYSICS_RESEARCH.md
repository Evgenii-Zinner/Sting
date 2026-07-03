# N-Body Physics Engine Research

## Objective
To create a physics engine capable of orchestrating complex astronomical entities with gravitational pull, specifically handling 1,000 to 5,000 objects efficiently at 60 FPS within the Sting engine's architecture.

## Algorithm Selection: Barnes-Hut Algorithm
Instead of calculating the gravitational pull of every single particle individually (which results in O(N^2) complexity), we will use the **Barnes-Hut algorithm**.

1. **Spatial Partitioning:** The space is grouped into a 2D Quadtree.
2. **Mass Summarization:** Each node in the quadtree calculates the total mass and the center of mass of all the objects contained within its boundary.
3. **Approximation:** When calculating the force on a specific object, if a quadtree node is "far enough away" (determined by a threshold ratio of the node's size to its distance), the entire quad and all its objects are treated as a single combined mass.

This approach drops the calculation complexity from O(N^2) to **O(N log N)**, making massive object counts manageable at 60 FPS.

## Architectural Approach: Data-Oriented Design (DOD)
To adhere to the Sting engine's zero-allocation per frame constraints and optimize for Dart's garbage collector, the implementation must use a strict Data-Oriented Design (DOD) / Struct-of-Arrays (SoA) approach.

* **Avoid Object Instances:** Do not represent planets or nodes as instances of a `Body` or `Node` class, which would cause severe CPU cache misses during iteration over thousands of objects.
* **Contiguous Memory:** Represent the physics world and quadtree using `Float32List` and `Int32List` from `dart:typed_data`. This keeps data contiguous in memory and maximizes cache friendliness.
* **Array Iteration:** Iterate over these raw arrays directly within the update loop, avoiding all object allocations.

## Implementation Steps
1. **Gravitational Components:** Create necessary flat array components (e.g., `Mass`) to work with existing kinematic components (`Position`, `Velocity`).
2. **Zero-Allocation Quadtree:** Implement a Quadtree algorithm using purely flat arrays (`Int32List`, `Float32List`) for nodes to handle spatial partitioning and mass summarization without instantiating objects per frame.
3. **Gravity System:** Implement an ECS System that recalculates the Quadtree every frame and applies gravitational forces to all entities using the Barnes-Hut approximation logic over the flat arrays.
