#[cfg(test)]
mod tests {
    use crate::queue::MyQueue;

    #[test]
    pub fn test_dequeue_empty() {
        let mut queue: MyQueue<i32, 4> = MyQueue::new();

        assert!(queue.dequeue().is_none());
    }

    #[test]
    pub fn test_enqueue_size() {
        let mut queue: MyQueue<i32, 4> = MyQueue::new();

        assert!(queue.enqueue(4).is_some());
        assert_eq!(queue.size(), 1);
    }

    #[test]
    pub fn test_enqueue_dequeue_value() {
        let mut queue: MyQueue<i32, 4> = MyQueue::new();

        assert!(queue.enqueue(4).is_some());
        assert_eq!(queue.dequeue(), Some(4));
    }

    #[test]
    pub fn test_enqueue_dequeue_many_values() {
        let mut queue: MyQueue<i32, 4> = MyQueue::new();

        assert!(queue.enqueue(4).is_some());
        assert!(queue.enqueue(5).is_some());
        assert_eq!(queue.dequeue(), Some(4));
        assert_eq!(queue.dequeue(), Some(5));
    }

    #[test]
    pub fn test_queue_full() {
        let mut queue: MyQueue<i32, 2> = MyQueue::new();

        assert!(queue.enqueue(4).is_some());
        assert!(queue.enqueue(5).is_some());
        assert!(queue.enqueue(6).is_none());

        assert_eq!(queue.size(), 2);
    }
}
