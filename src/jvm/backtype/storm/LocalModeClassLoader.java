package backtype.storm;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.ArrayList;
import java.util.List;

public class LocalModeClassLoader extends URLClassLoader {
    private static URL[] urls;
    
    static {
        String userDir = System.getProperty("user.dir");
        String classesDir = userDir + "/classes";
        String libDir = userDir + "/lib";
        
        File libFile = new File(libDir);
        List<URL> urlList = new ArrayList<URL>();
        try {
            urlList.add(new File(classesDir).toURI().toURL());
        } catch (MalformedURLException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        for (File file : libFile.listFiles()) {
            try {
                urlList.add(file.toURI().toURL());
            } catch (MalformedURLException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        }
        
        urls = new URL[urlList.size()];
        urlList.toArray(urls);
    }
    public LocalModeClassLoader() {
        super(urls);
    }
    
    public LocalModeClassLoader(ClassLoader parent) {
        super(urls, parent);
    }
}
