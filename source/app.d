import core.thread;
import std.algorithm.sorting;
import std.array;
import std.concurrency;
import std.datetime.stopwatch;
import std.stdio;
import std.typecons : Tuple, tuple;
import std.range;

import hidraw;
import img;
import lcd;

enum Comms {
    FATAL_ERROR,
    READY
};

struct FrameData {
    immutable ubyte[] buf;
    immutable MonoTime ts;
    immutable ulong frame_id;

    this(ubyte[] buf, MonoTime ts, ulong frame_id) {
        this.buf = cast(immutable) buf.dup;
        this.ts = ts;
        this.frame_id = frame_id;
    }
}

void presenter_thread(Tid parentTid) {
    hidraw_devinfo[] hidraw_ids = [
        {BUS_USB, 0x046d, 0xc222},
        {BUS_USB, 0x046d, 0xc227}
    ];

    auto hn = find_device(hidraw_ids);
    if(hn.isNull) {
        writeln("Could not find a G15 :(");
        send(parentTid, Comms.FATAL_ERROR);
        return;
    }
    auto h = hn.get;
    send(parentTid, Comms.READY);
    try {
        while(1) {
            receive(
                /* What to present, and when */
                (FrameData f) {
                    Duration remaining = f.ts - MonoTime.currTime();
                    writeln(remaining);
                    if(remaining > Duration.zero) {
                        Thread.sleep(abs(remaining));
                    }
                    send_data(h, f.buf);
                    send(parentTid, f.frame_id);
                }
            );
        }
    } catch(OwnerTerminated) {

    }
}

/* returns a sorted list of the directory entries matching pattern */
string[] get_sorted_filenames(string path, string pattern) {
    import std.file : dirEntries, SpanMode;
    import std.format : formattedRead;
    import std.path : chainPath;
    auto ap = appender!(Tuple!(string, int)[]);
    ap.reserve(1000);
    string p = chainPath(path, pattern).array;
    foreach(f; dirEntries(path, SpanMode.shallow)) {
        int read, num;
        read = f.name.formattedRead(p, &num);
        if(read != 0) {
            ap.put!(Tuple!(string, int))(tuple(f.name, num));
        }
    }
    alias srt = (x, y) => x[1] < y[1];
    auto a = sort!(srt)(ap[]);
    auto ret = new string[a.length];
    foreach(i, t; enumerate(a)) {
        ret[i] = t[0];
    }
    return ret;
}

int main() {
    Image!(Pixel!(ubyte, 3)) im;
    MonoImage im_m;
    ubyte[] buf;

    auto son = spawn(&presenter_thread, thisTid);
    setMaxMailboxSize(son, 4, OnCrowding.block);
    while(1) {
        auto c = receiveOnly!Comms();
        if(c == Comms.FATAL_ERROR) {
            return -1;
        } else if(c == Comms.READY) {
            break;
        }
    }

    auto mt = MonoTime.currTime();
    ulong nframes = 0;
    foreach(fname; get_sorted_filenames("/tmp/badapple/out/", "badapple_%d.ppm")) {
        writeln(fname);
        auto f = File(fname, "rb");
        im = load_ppm_image!(ubyte)(f);
        f.close();
        buf = pixmap_to_lcd(to_mono_pixbuf(im));
        FrameData frd = FrameData(buf, mt, nframes);
        son.send(frd);
        //mt += 66666.nsecs;
        mt += 66.msecs;
        nframes++;
    }
    writeln("im done");
    while(receiveOnly!(immutable ulong)() != nframes - 1) {}

    return 0;
}
