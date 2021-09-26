import rclpy
from rclpy.node import Node

from mdef_a2sat.msg import AckMision    # CHANGE


class MinimalPublisher(Node):

    def __init__(self):
        super().__init__('minimal_publisher')
        self.publisher_ = self.create_publisher(AckMision, 'topic55', 10)     # CHANGE
        timer_period = 0.5
        self.timer = self.create_timer(timer_period, self.timer_callback)
        self.i = 0

    def timer_callback(self):
        msg = AckMision()                                           # CHANGE
        msg.tipo = self.i 
        msg.ack = True 
        msg.notas = "Hola" 
        self.publisher_.publish(msg)
        self.get_logger().info('Publishing: "%d"' % msg.tipo)  # CHANGE
        self.get_logger().info('Publishing: "%i"' % msg.ack)  # CHANGE
        self.get_logger().info('Publishing: "%s"' % msg.notas)  # CHANGE
        self.i += 1


def main(args=None):
    rclpy.init(args=args)

    minimal_publisher = MinimalPublisher()

    rclpy.spin(minimal_publisher)

    minimal_publisher.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
