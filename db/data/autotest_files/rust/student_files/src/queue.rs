pub struct MyQueue<T, const N: usize> {
    count: usize,
    start: usize,
    buffer: [Option<T>; N] // We could use MaybeUninit here instead.
}

impl<T, const N: usize> MyQueue<T, N> {
    pub fn new() -> MyQueue<T, N> {
        // Fill array with None (we don't have Copy + Clone so buffer: [None; N] is no good!)
        MyQueue {
            count: 0,
            start: 0,
            buffer: std::array::from_fn(|_| None)
        }
    }

    pub fn enqueue(&mut self, value: T) -> Option<()> {
        if self.count >= N {
            return None
        }

        let end = (self.start + self.count) % N;

        self.buffer[end] = Some(value);

        self.count += 1;

        Some(())
    }

    pub fn dequeue(&mut self) -> Option<T> {
        if self.count <= 0 {
            return None
        }

        let value = self.buffer[self.start].take();

        self.count -= 1;

        // Intentional error for tests to catch.
        // self.start += 1;

        value
    }

    pub fn size(&self) -> usize {
        self.count
    }
}
