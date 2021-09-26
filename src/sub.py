import rclpy
from rclpy.node import Node

from mdef_a2sat.msg import AckMision        # CHANGE


class MinimalSubscriber(Node):

    def __init__(self):
        super().__init__('minimal_subscriber')
        self.subscription = self.create_subscription(
            AckMision,                                              # CHANGE
            'topic55',
            self.listener_callback,
            10)
        self.subscription

    def listener_callback(self, msg):
            self.get_logger().info('I heard: "%i "' % msg.ack) # CHANGE
            self.get_logger().info('I heard: "%d "' % msg.tipo) # CHANGE
            self.get_logger().info('I heard: "%s "' % msg.notas) # CHANGE


def main(args=None):
    rclpy.init(args=args)

    minimal_subscriber = MinimalSubscriber()

    rclpy.spin(minimal_subscriber)

    minimal_subscriber.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
