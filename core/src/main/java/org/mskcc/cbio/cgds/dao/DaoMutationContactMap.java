/** Copyright (c) 2012 Memorial Sloan-Kettering Cancer Center.
**
** This library is free software; you can redistribute it and/or modify it
** under the terms of the GNU Lesser General Public License as published
** by the Free Software Foundation; either version 2.1 of the License, or
** any later version.
**
** This library is distributed in the hope that it will be useful, but
** WITHOUT ANY WARRANTY, WITHOUT EVEN THE IMPLIED WARRANTY OF
** MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  The software and
** documentation provided hereunder is on an "as is" basis, and
** Memorial Sloan-Kettering Cancer Center 
** has no obligations to provide maintenance, support,
** updates, enhancements or modifications.  In no event shall
** Memorial Sloan-Kettering Cancer Center
** be liable to any party for direct, indirect, special,
** incidental or consequential damages, including lost profits, arising
** out of the use of this software and its documentation, even if
** Memorial Sloan-Kettering Cancer Center 
** has been advised of the possibility of such damage.  See
** the GNU Lesser General Public License for more details.
**
** You should have received a copy of the GNU Lesser General Public License
** along with this library; if not, write to the Free Software Foundation,
** Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
**/
package org.mskcc.cbio.cgds.dao;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import org.mskcc.cbio.cgds.model.ExtendedMutation;

/**
 *
 * @author jgao
 */
public class DaoMutationContactMap {
    private static MySQLbulkLoader myMySQLbulkLoader = null;
    private DaoMutationContactMap() {}
    
    private static MySQLbulkLoader getMyMySQLbulkLoader() {
        if (myMySQLbulkLoader==null) {
            myMySQLbulkLoader = new MySQLbulkLoader("mutation_contact_map");
        }
        return myMySQLbulkLoader;
    }
    
    public static int addDaoMutationContactMap(int mutId1, int mutId2, String pdbId,
            String chain, double distance) throws DaoException {
        Connection con = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        if (MySQLbulkLoader.isBulkLoad()) {
            //  write to the temp file maintained by the MySQLbulkLoader
            getMyMySQLbulkLoader().insertRecord(pdbId, chain, Integer.toString(mutId1),
                    Integer.toString(mutId1), Double.toString(distance));

            // return 1 because normal insert will return 1 if no error occurs
            return 1;
        } else {
            try {
                con = JdbcUtil.getDbConnection(DaoPdbUniprotResidueMapping.class);
                pstmt = con.prepareStatement("INSERT INTO mutation_contact_map " +
                        "( `PDB_ID`, `CHAIN`, `MUTATION_EVENT_ID1`, `MUTATION_EVENT_ID2`, `DISTANCE`)"
                        + " VALUES (?,?,?,?,?)");
                pstmt.setString(1, pdbId);
                pstmt.setString(2, chain);
                pstmt.setInt(3, mutId1);
                pstmt.setInt(4, mutId2);
                pstmt.setDouble(5, distance);
                int rows = pstmt.executeUpdate();
                return rows;
            } catch (SQLException e) {
                throw new DaoException(e);
            } finally {
                JdbcUtil.closeAll(DaoPdbUniprotResidueMapping.class, con, pstmt, rs);
            }
        }
    }
    
    public static int flushToDatabase() throws DaoException {
        try {
            return getMyMySQLbulkLoader().loadDataFromTempFileIntoDBMS();
        } catch (IOException e) {
            System.err.println("Could not open temp file");
            e.printStackTrace();
            return -1;
        }
    }
}
