/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package kibera;

// Haiti project  - searching the nearest road

import kibera.KiberaBuilder.Node;

import java.util.ArrayList;
import java.util.HashMap;

import sim.field.network.Edge;

@SuppressWarnings("restriction")
public class AStar {

	/**
	 * Assumes that both the start and end location are NODES as opposed to LOCATIONS
	 * @param world
	 * @param start
             * @param goal
	 * @return
	 */
	public ArrayList <Parcel> astarPath(Kibera world, Node start, Node goal){

		// initial check
		if(start == null || goal == null)
			System.out.println("Error: invalid node provided to AStar");

		// containers for the metainformation about the Nodes relative to the 
		// A* search
		HashMap <Node, AStarNodeWrapper> foundNodes = 
			new HashMap <Node, AStarNodeWrapper> ();
		
		
		AStarNodeWrapper startNode = new AStarNodeWrapper(start);
		AStarNodeWrapper goalNode = new AStarNodeWrapper(goal);
		foundNodes.put( start, startNode);
		foundNodes.put(goal, goalNode);

		startNode.gx = 0;
		startNode.hx = heuristic(start,goal);
		startNode.fx = heuristic(start,goal);

		// A* containers: nodes to be investigated, nodes that have been investigated
		ArrayList <AStarNodeWrapper> closedSet = new ArrayList <AStarNodeWrapper>(), 
			openSet = new ArrayList <AStarNodeWrapper> ();
		openSet.add(startNode);
		
				
		while(openSet.size() > 0){ // while there are reachable nodes to investigate

			AStarNodeWrapper x = findMin(openSet); // find the shortest path so far
			if(x.node == goal ){ // we have found the shortest possible path to the goal! 
				// Reconstruct the path and send it back.
				return reconstructPath(goalNode);
			}
			openSet.remove(x); // maintain the lists
			closedSet.add(x);
			
			// check all the neighbors of this location
			for(Edge l: x.node.links){
				
				Node n = (Node) l.from();
				if( n == x.node )
					n = (Node) l.to();
				
				// get the A* meta information about this Node
				AStarNodeWrapper nextNode;
				if( foundNodes.containsKey(n))
					nextNode = foundNodes.get(n);
				else{
					nextNode = new AStarNodeWrapper(n);
					foundNodes.put( n, nextNode );
				}

				if(closedSet.contains(nextNode)) // it has already been considered
					continue;

				// otherwise evaluate the cost of this node/edge combo
				double tentativeCost = x.gx + (Integer) l.info;
				boolean better = false;
				
				if(! openSet.contains(nextNode)){
					openSet.add(nextNode);
					nextNode.hx = heuristic(n, goal);
					better = true;
				}
				else if(tentativeCost < nextNode.gx){
					better = true;
				}
				
				// store A* information about this promising candidate node
				if(better){
					nextNode.cameFrom = x;
					nextNode.gx = tentativeCost;
					nextNode.fx = nextNode.gx + nextNode.hx;
				}
			}
		}
		
		return null;
	}	
	
	/**
	 * Takes the information about the given node n and returns the path that
	 * found it.
	 * @param n the end point of the path
	 * @return an ArrayList of nodes that lead from the
	 * given Node to the Node from which the search began 
	 */
	ArrayList <Parcel> reconstructPath( AStarNodeWrapper n){
		ArrayList <Parcel> result = new ArrayList <Parcel> ();
		AStarNodeWrapper x = n;
		while( x.cameFrom != null ){
			result.add(0, x.node.location); // add this edge to the front of the list
			x = x.cameFrom;
		}
		
		return result;
	}
	
	/**
	 * Measure of the estimated distance between two Nodes.
	 * @return notional "distance" between the given nodes.
	 */
	double heuristic(Node x, Node y){
		return x.location.distanceTo(y.location);
	}

	
	/**
	 *  Considers the list of Nodes open for consideration and returns the node 
	 *  with minimum fx value
	 * @param set list of open Nodes
	 * @return
	 */
	AStarNodeWrapper findMin(ArrayList <AStarNodeWrapper> set){
		double min = 100000;
		AStarNodeWrapper minNode = null;
		for(AStarNodeWrapper n: set){
			if(n.fx < min){
				min = n.fx;
				minNode = n;
			}
		}
		return minNode;
	}
	
	/**
	 * A wrapper to contain the A* meta information about the Nodes
	 *
	 */
	class AStarNodeWrapper {
		
		// the underlying Node associated with the metainformation
		Node node;

		// the Node from which this Node was most profitably linked
		AStarNodeWrapper cameFrom;
		
		double gx, hx, fx;

		public AStarNodeWrapper( Node n){
			node = n;
			gx = 0;
			hx = 0;
			fx = 0;
			cameFrom = null;
		}
		
	}
}