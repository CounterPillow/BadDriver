import core.sys.posix.sys.ioctl;
import core.stdc.string;
import std.stdio;
import std.file : dirEntries, SpanMode;
import std.typecons : Nullable;

// According to <linux/input.h>
enum int BUS_USB = 0x03;

// According to <linux/hid.h>
enum int HID_MAX_DESCRIPTOR_SIZE = 4096;

enum LIB_HIDRAW_DESC_HDR_SZ = 16;

struct hidraw_handle {
    hidraw_devinfo hid;
    File* f;
}

struct hidraw_devinfo {
    uint bustype;
    ushort vendor;
    ushort product;
};
struct hidraw_report_descriptor {
    uint size;
    ubyte[HID_MAX_DESCRIPTOR_SIZE] value;
};

enum HIDIOCGRDESC = _IOR!hidraw_report_descriptor('H', 0x02);
enum HIDIOCGRAWINFO = _IOR!hidraw_devinfo('H', 0x03);


Nullable!hidraw_handle open_device(string devname, hidraw_devinfo[] hids) {
    auto f = new File(devname, "r+");
    hidraw_devinfo devinfo;
    hidraw_report_descriptor descriptor;
    descriptor.size = LIB_HIDRAW_DESC_HDR_SZ;

    if(ioctl(f.fileno, HIDIOCGRAWINFO, &devinfo) == -1) {
        throw new StdioException("Failed to ioctl HIDIOCGRAWINFO");
    }

    if(ioctl(f.fileno, HIDIOCGRDESC, &descriptor) == -1) {
        throw new StdioException("Failed to ioctl HIDIOCGRDESC");
    }

    Nullable!hidraw_handle h;

    foreach(id; hids) {
        if(devinfo != id) {
            continue;
        }
        h = hidraw_handle(id, f);
        break;
    }
    return h;
}


Nullable!hidraw_handle find_device(hidraw_devinfo[] hids) {
    Nullable!hidraw_handle h;
    foreach(f; dirEntries("/dev/", "hidraw*", SpanMode.shallow)) {
        try {
            h = open_device(f, hids);
            if(!h.isNull) {
                break;
            }
        } catch (Exception e) {
        }
    }
    return h;
}
