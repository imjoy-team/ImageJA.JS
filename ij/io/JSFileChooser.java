package ij.io;

import ij.IJ;
import java.awt.Component;
import java.awt.EventQueue;
import java.io.File;
import javax.swing.JFileChooser;
import com.leaningtech.client.Global;

/**
 * This class provides the functionality to get a file path
 * from a file dialog in Javascript
 *
 * @author Wei OUYANG
 */
public class JSFileChooser extends JFileChooser {
    private static final long serialVersionUID = 1L;
    // Getting a file from javascript
	// Either selected from internal file system or uploaded
    private static String jsFilePath;
    private static Object jsLock;
	public interface Promise{
		void resolve(String result);
		void reject(String error);
	}

	public static String showFileDialogJS(String func, String title, String initPath, int selectionMode){
        jsFilePath = null;
        jsLock = new Object();
        Global.jsCall(func, title, initPath, selectionMode, new Promise(){
            public void resolve(String path){
                // make sure it's not null
                if(path == null) path = "";
                jsFilePath = path;
                jsLock.notify();
            }
            public void reject(String error){
                jsFilePath = null;
                jsLock.notify();
            }
        });
        try{
            jsLock.wait();  
        }
        catch(InterruptedException e){
            return null;
        }
        
		return jsFilePath;
    }

    @Override
    public int showOpenDialog(Component parent) {
        return showOpenDialog(parent, "openFileDialogJS");
    }

    @Override
    public int showSaveDialog(Component parent){
        return showOpenDialog(parent, "saveFileDialogJS");
    }

    int showOpenDialog(Component parent, String func){
        String title = super.getDialogTitle();

        // This is necessary because Global.jsCall cannot allow passing null
        if(title == null) title = "";

        String defaultFile;
        if(super.getSelectedFile()==null){
            defaultFile = "";
        }
        else{
            defaultFile = super.getSelectedFile().getPath();
        }

        String ret = showFileDialogJS(func, title, defaultFile, super.getFileSelectionMode());
        if(ret == null) {
            return JFileChooser.CANCEL_OPTION;
        }
        else if(ret.isEmpty()){
            return super.showOpenDialog(parent);
        }
        else{
            File f = new File(ret);
            if (IJ.debugMode)
                IJ.log("JSFileChooser,setSelectedFile: "+f);
            super.setSelectedFile(f);
            return JFileChooser.APPROVE_OPTION;
        }
            
    }


}
