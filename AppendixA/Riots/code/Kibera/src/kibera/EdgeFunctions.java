package kibera;

import sim.field.network.Edge;
import sim.util.Bag;

public class EdgeFunctions {

	public static boolean doesEdgeExist(Resident node1, Resident node2, Kibera kibera) {
		
		Bag myConnections = new Bag(kibera.socialNetwork.getEdgesOut(node1));
		//boolean edgeExists = false;
		
		if (myConnections != null) {
		
			for (int i = 0; i < myConnections.size(); i++) {
				Edge e = (Edge)(myConnections.get(i));
				Resident otherNode = (Resident) e.getOtherNode(node1);
				if (otherNode == node2) {
					return true;
				}
			}
		}
		
		return false;
		
	}
	
	public static Edge getEdge(Resident node1, Resident node2, Kibera kibera) {
		
		Bag myConnections = new Bag(kibera.socialNetwork.getEdgesOut(node1));
		Edge myEdge = null;
                
                
                
		if (myConnections != null) {
		
			for (int i = 0; i < myConnections.size(); i++) {
				Edge e = (Edge)(myConnections.get(i));
				Resident otherNode = (Resident) e.getOtherNode(node1);
				if (otherNode == node2) {
					return e;
				}
			}
		}
		
		return null;
	}
}
