package backtype.storm;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.Collection;
import java.util.Enumeration;

public class StormClassLoader extends URLClassLoader {
    public static StormClassLoader create(Collection<String> urls) {
        URL[] urlArr = string2Url(urls);
        return new StormClassLoader(urlArr);
    }

    public static StormClassLoader create(Collection<String> urls, ClassLoader parent) {
        URL[] urlArr = string2Url(urls);
        return new StormClassLoader(urlArr, parent);
    }
    public StormClassLoader(URL[] urls){
        super(urls);
    }

    public StormClassLoader(URL[] urls, ClassLoader parentLoader) {
        super(urls, parentLoader);
    }
    
    @Override
    public synchronized Class<?> loadClass(String name)
            throws ClassNotFoundException {
        Class<?> clazz = this.findLoadedClass(name);
        
        if (clazz == null) {
            try {
                clazz = this.findClass(name);
            } catch (ClassNotFoundException e) {
                // empty
            }
            
            if (clazz == null) {
                clazz = this.getParent().loadClass(name);
            }
        }
        
        return clazz;
    }
    
    public Enumeration<URL> getResources(String name) throws IOException {
        Enumeration<URL> ret = this.findResources(name);
        
        if (ret == null || !ret.hasMoreElements()) {
            ret = this.getParent().getResources(name);
        }
        
        return ret;
    }
    

    private static URL[] string2Url(Collection<String> urls) {
        URL[] urlArr = new URL[urls.size()];
        int idx = 0;
        for (String url : urls) {
            try {
                System.out.println("processing url: " + url);
                urlArr[idx] = new File(url).toURI().toURL();
                idx++;
            } catch (MalformedURLException e) {
                e.printStackTrace();
            }
        }
        return urlArr;
    }
}
