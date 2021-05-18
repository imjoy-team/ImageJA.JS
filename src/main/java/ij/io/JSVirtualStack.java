package ij.io;
import ij.*;
import ij.process.*;
import ij.gui.*;
import ij.io.*;
import ij.util.Tools;
import java.awt.*;
import java.awt.image.*;
import java.io.*;
import java.util.*;
import com.leaningtech.client.Global;


/** This plugin opens images loaded dynamically through Javascript */
public class JSVirtualStack extends VirtualStack {
	private int nImages;
	private int imageWidth, imageHeight;
	private String fileKey;
	private static Object jsLock;
	private FileInfo fi;
	private byte[] bytes = null;

	public interface Promise{
		void resolve(byte[] result);
		void reject(String error);
	}

	public JSVirtualStack(String fileKey, int imageWidth, int imageHeight, int nImages, int type, String title) {
		this.fileKey = fileKey;
		this.imageHeight = imageHeight;
		this.imageWidth = imageWidth;
		this.nImages = nImages;

		FileInfo fi = new FileInfo();
		fi.fileName = title;
    	fi.width = imageWidth;
    	fi.height = imageHeight;
    	fi.nImages = nImages;
		fi.whiteIsZero = false;
		// we need to set intel byte order for js typedarray byte ordering
		fi.intelByteOrder = true;
		switch (type) {
			case ImagePlus.GRAY8: case ImagePlus.COLOR_256:
				if (type==ImagePlus.COLOR_256)
					fi.fileType = FileInfo.COLOR8;
				else
					fi.fileType = FileInfo.GRAY8;
				break;
	    	case ImagePlus.GRAY16:
				fi.fileType = fi.GRAY16_UNSIGNED;
				break;
	    	case ImagePlus.GRAY32:
				fi.fileType = fi.GRAY32_FLOAT;
				break;
	    	case ImagePlus.COLOR_RGB:
				fi.fileType = fi.RGB;
				break;
			default:
    	}
		this.fi = fi;
	}

	ImageStack convertToRealStack(ImagePlus imp) {
		ImageStack stack2 = new ImageStack(imageWidth, imageHeight, imp.getProcessor().getColorModel());
		int n = this.getSize();
		for (int i=1; i<=this.getSize(); i++) {
			IJ.showProgress(i, n);
			IJ.showStatus("Opening: "+i+"/"+n);
			ImageProcessor ip2 = this.getProcessor(i);
			if (ip2!=null)
				stack2.addSlice(this.getSliceLabel(i), ip2);
		}
		return stack2;
	}

	public ColorModel createColorModel(FileInfo fi) {
		if (fi.lutSize>0)
			return new IndexColorModel(8, fi.lutSize, fi.reds, fi.greens, fi.blues);
		else
			return LookUpTable.createGrayscaleColorModel(fi.whiteIsZero);
	}

	public ImagePlus readImage(int index){
		jsLock = new Object();
		bytes = null;
		Global.jsCall("getVirtualStackSlice", this.fileKey, index, new Promise(){
            public void resolve(byte[] data){
                bytes = data;
				jsLock.notify();
            }
            public void reject(String error){
                jsLock.notify();
            }
        });
		try{
            jsLock.wait();  
        }
        catch(InterruptedException e){
            return null;
        }
		FileInfo fi = this.fi;
		InputStream is = new ByteArrayInputStream(bytes);
		ImageReader reader = new ImageReader(fi);

		ImagePlus imp = null;
		ColorModel cm = createColorModel(fi);
		ImageProcessor ip;

		Object pixels = reader.readPixels(is);
		if (pixels==null) return null;

		switch (fi.fileType) {
			case FileInfo.GRAY8:
			case FileInfo.COLOR8:
			case FileInfo.BITMAP:
				ip = new ByteProcessor(fi.width, fi.height, (byte[])pixels, cm);
    			imp = new ImagePlus(fi.fileName, ip);
				break;
			case FileInfo.GRAY16_SIGNED:
			case FileInfo.GRAY16_UNSIGNED:
			case FileInfo.GRAY12_UNSIGNED:
	    		ip = new ShortProcessor(fi.width, fi.height, (short[])pixels, cm);
       			imp = new ImagePlus(fi.fileName, ip);
				break;
			case FileInfo.GRAY32_INT:
			case FileInfo.GRAY32_UNSIGNED:
			case FileInfo.GRAY32_FLOAT:
			case FileInfo.GRAY24_UNSIGNED:
			case FileInfo.GRAY64_FLOAT:
	    		ip = new FloatProcessor(fi.width, fi.height, (float[])pixels, cm);
       			imp = new ImagePlus(fi.fileName, ip);
				break;
		}
		return imp;
	}
	
	/** Returns an ImageProcessor for the specified slice,
		were 1<=n<=nslices. Returns null if the stack is empty.
	*/
	public ImageProcessor getProcessor(int n) {
		if (n<1 || n>nImages)
			throw new IllegalArgumentException("Argument out of range: "+n);
		IJ.redirectErrorMessages(true);
		ImagePlus imp = readImage(n);
		if (imp!=null) {
			ImageProcessor ip =  imp.getProcessor();
			int bitDepth = getBitDepth();
			if (imp.getBitDepth()!=bitDepth) {
				switch (bitDepth) {
					case 8: ip=ip.convertToByte(true); break;
					case 16: ip=ip.convertToShort(true); break;
					case 24:  ip=ip.convertToRGB(); break;
					case 32: ip=ip.convertToFloat(); break;
				}
			}
			if (ip.getWidth()!=imageWidth || ip.getHeight()!=imageHeight)
			ip = ip.resize(imageWidth, imageHeight);
			IJ.redirectErrorMessages(false);
			return ip;
		} else {
				ImageProcessor ip = null;
				switch (getBitDepth()) {
					case 8: ip=new ByteProcessor(imageWidth,imageHeight); break;
					case 16: ip=new ShortProcessor(imageWidth,imageHeight); break;
					case 24:  ip=new ColorProcessor(imageWidth,imageHeight); break;
					case 32: ip=new FloatProcessor(imageWidth,imageHeight); break;
				}
			IJ.redirectErrorMessages(false);
			return ip;
		}
	 }
 
	 /** Returns the number of images in this stack. */
	public int getSize() {
		return nImages;
	}

	/** Returns the name of the specified image. */
	public String getSliceLabel(int n) {
		if (n<1 || n>nImages)
			throw new IllegalArgumentException("Argument out of range: "+n);
		return "Slice " + n;
	}
	
	public int getWidth() {
		return imageWidth;
	}

	public int getHeight() {
		return imageHeight;
	}


}
