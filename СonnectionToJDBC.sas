import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;
import com.sas.iom.*;
import com.sas.rio.MVAConnection;
import com.sas.services.connection.*;


public class СonnectionToJDBC {
    public static void main(String[] args)  {

        //Входные данные:
        String host = "test.server.ru";
        int port = 8592;
        String user = "test";
        String password = "test";

        MVAConnection jdbcConnection = null; //подключение к базе
        Statement stmt = null;
        IWorkspace sasWorkspace = null; //интерфейс для подключения к серверу
        
        try {
            String classID = Server.CLSID_SAS;
            // Подключаемся к серверу
            Server server = new BridgeServer(classID, host, port); //создаем объект, описывающий  сервер
            ConnectionFactoryConfiguration cxfConfig = new ManualConnectionFactoryConfiguration(
                    server); //создание и управление подключениями к конкретному серверу
            ConnectionFactoryManager cxfManager = new ConnectionFactoryManager();
            ConnectionFactoryInterface cxf = cxfManager.getFactory(cxfConfig);    
            ConnectionInterface cx = cxf.getConnection(user, password); //описание подключения (по логину-паролю)
            org.omg.CORBA.Object obj = cx.getObject();
            sasWorkspace = IWorkspaceHelper.narrow(obj);        

            //Language.Submit позволяет вставлять sas-код.
            ILanguageService sasLanguage = sasWorkspace.LanguageService();
            sasLanguage.Submit("libname shrtest '//lib';");
            
            // Вынимаются логи
            CarriageControlSeqHolder logCarriageControlHldr = new CarriageControlSeqHolder(); /
            LineTypeSeqHolder logLineTypeHldr = new LineTypeSeqHolder();
            StringSeqHolder logHldr = new StringSeqHolder();     
            sasLanguage.FlushLogLines(Integer.MAX_VALUE,      
                    logCarriageControlHldr, logLineTypeHldr, logHldr);
            String[] logLines = logHldr.value;
            for (int i = 0; i < logLines.length; i++) {
                System.out.println(logLines[i]); //выводим в консоль построчно лог
            }

            // Создаем новое подключение к базе, sql-запрос
            Properties jdbcProps = new Properties();
            jdbcConnection = new MVAConnection(sasWorkspace, jdbcProps);

            stmt = jdbcConnection.createStatement();
            ResultSet rs = stmt.executeQuery("select * from shrtest.dict");
            
            // Печатаем только заголовки колонок
            while (rs.next()){
                System.out.println(rs.getString("title_str"));
                //http://docs.oracle.com/javase/6/docs/api/java/sql/ResultSetMetaData.html
            }
     
        } catch (SQLException e) {
            e.printStackTrace();
        } catch (ConnectionFactoryException e) {
            e.printStackTrace();
        } catch (GenericError e) {
            e.printStackTrace();
        } finally {
            try {
                if (null != stmt) {
                    stmt.close();
                }
                if (null != jdbcConnection) {
                    jdbcConnection.close();
                    sasWorkspace.Close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            } catch (GenericError e) {
                e.printStackTrace();
            }

        }
    }

}
