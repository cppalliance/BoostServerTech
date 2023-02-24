#include <boost/buffers.hpp>
#include <boost/http_proto.hpp>
#include <boost/http_io.hpp>
#include <boost/asio.hpp>

auto main() -> int
{
    // buffers
    {
        char temp[16];
        boost::buffers::circular_buffer cb( temp, sizeof(temp) );
        cb.prepare(5);
        cb.commit(3);
        cb.data();
    }

    // http_proto
    {
        boost::http_proto::context ctx;
    }

    // http_io
    {
        boost::http_proto::context ctx;
        boost::http_proto::serializer sr(4096);
        boost::asio::io_context ioc;
        boost::asio::ip::tcp::socket sock(ioc);
        boost::http_io::async_write(
            sock, sr, [](
            boost::system::error_code,
            std::size_t)
            {
            });

    }
}
