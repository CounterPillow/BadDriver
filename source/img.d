import std.array : uninitializedArray;
import std.algorithm.iteration : sum;
import std.stdio;
import std.exception : enforce;
struct Pixel(T, uint n) {
    /*foreach(index, Type; T) {
        mixin("T v" ~ index ~ ";")
    }*/
    T[n] v;
}

class Image(T) {
    enum AllocMode {
        INITIALISE,
        NO_INITIALISE,
        NO_ALLOC
    }
    uint width;
    uint height;
    T[] data;

    this(uint width, uint height, AllocMode m = AllocMode.NO_INITIALISE) {
        this.width = width;
        this.height = height;
        if(m != AllocMode.NO_ALLOC) {
            if(m == AllocMode.NO_INITIALISE) {
                this.data = uninitializedArray!(T[])(width * height);
            } else {
                this.data = new T[width * height];
            }
        }
    }

    const T get(uint x, uint y) {
        return this.data[y * this.width + x];
    }

    void set(uint x, uint y, T value) {
        this.data[y * this.width + x] = value;
    }
}


alias MonoPixel = Pixel!(ubyte, 1);
alias MonoImage = Image!(MonoPixel);

Image!(Pixel!(ubyte, 1)) to_mono_pixbuf(T)(Image!T img) {
    auto mb = new Image!((Pixel!(ubyte, 1)))(img.width, img.height);
    for(uint row = 0; row < img.height; row++) {
        for(uint col = 0; col < img.width; col++) {
            auto p = img.get(col, row);
            ulong s = 0;
            foreach(e; p.v) {
                s += e;
            }
            s = s / p.v.length;
            mb.data[row * mb.width + col].v[0] = cast(ubyte) s;
        }
    }
    return mb;
}

/* Loads a PPM image, but technically does not follow the spec as we don't accept
 * any whitespace (for simplicity)
 */
Image!(Pixel!(T, 3)) load_ppm_image(T)(File f) {
    import std.bitmanip;
    string magic = f.readln();
    enforce(magic == "P6\n");
    uint width, height, maxval;
    f.readf!"%d %d\n%d\n"(width, height, maxval);
    enforce(maxval <= T.max);
    auto im = new Image!(Pixel!(T, 3))(width, height);
    static if(T.sizeof > 1) {
        uint[T.sizeof] buf;
        for(uint row = 0; row < im.height; row++) {
            for(uint col = 0; col < im.width; col++) {
                im.data[row * im.width + col] = bigEndianToNative!T(f.rawRead(buf));
            }
        }
    } else {
        im.data = f.rawRead(im.data);
    }
    return im;
}
