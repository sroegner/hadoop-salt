/**
 * Created with IntelliJ IDEA.
 * User: Steffen Roegner
 * Date: 11/18/13
 * Time: 5:19 AM
 */
package com.sqrrl.provisioning;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.security.AccessControlException;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class HdfsAvailableTest {

    private Configuration conf;
    private FileSystem fileSystem;
    private Properties prop;


    @Before
    public void runBefore() {
        conf = new Configuration();
        prop = new Properties();
        try {
            String fileName = System.getenv("TEST_PROPERTIES_FILE");
            System.err.println("Reading master IP from " + fileName );
            prop.load(new FileInputStream(fileName));
            String masterUrl = "hdfs://" + prop.getProperty("ci.accumulo.master") + ":8020";
            System.err.println("Will attempt to connect " + masterUrl );
            conf.set("fs.default.name", masterUrl);
            fileSystem = FileSystem.get(conf);
        } catch (Exception e) {
            e.printStackTrace();

        }
    }

    @Test
    public void testHdfsAvailable() {
        Path path = new Path("/");
        try {
            Boolean has_root = fileSystem.exists(path);
            Assert.assertTrue(has_root);
        } catch (IOException e) {
            e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
        }
    }

    @Test(expected=AccessControlException.class)
    public void testAccumuloInitialized() throws IOException {
        // hdfs is not supposed to let me read this here
        Path path = new Path("/accumulo/instance_id");
        Boolean has_instance_id = fileSystem.exists(path);
    }

}